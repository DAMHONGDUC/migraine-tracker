import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/tables/attack_tables.dart';
import '../../features/attacks/domain/enums/exertion_level.dart';
import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/medications/data/tables/medication_tables.dart';
import '../../features/settings/data/tables/export_tables.dart';
import '../../features/sync/data/tables/sync_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/tables/attack_tables.dart';
export '../../features/medications/data/tables/medication_tables.dart';
export '../../features/settings/data/tables/export_tables.dart';
export '../../features/sync/data/tables/sync_tables.dart';

part 'app_database.g.dart';

/// The single on-device database. Tables are owned by their features; this
/// class only composes them into one SQLite file.
@DriftDatabase(
  tables: [
    Attacks,
    WeatherSnapshots,
    Medications,
    MedicationReminders,
    ExportRecords,
    SyncTombstones,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: daily medication reminders.
      if (from < 2) {
        await m.createTable(medicationReminders);
      }
      // - v3: medications remember when they were added, so the tab can sort/filter by it.
      // - Existing rows get null — inventing a date would corrupt the very filter this serves.
      if (from < 3) {
        await m.addColumn(medications, medications.createdAt);
      }
      // - v4: the export screen keeps a history.
      // - Nothing to backfill — exports before this shipped were never recorded.
      if (from < 4) {
        await m.createTable(exportRecords);
      }
      // - v5: self-reported physical exertion, added to the details step.
      // - Existing rows get null — nobody reported exertion before this shipped.
      if (from < 5) {
        await m.addColumn(attacks, attacks.exertionLevel);
      }
      // - v6: sync state per attack, for encrypted upload once signed in.
      // - Existing rows land at revision 0 with nothing confirmed, which is
      //   what makes the first sync push the whole history.
      if (from < 6) {
        await m.addColumn(attacks, attacks.updatedAt);
        await m.addColumn(attacks, attacks.revision);
        await m.addColumn(attacks, attacks.syncedRevision);
        // v6's own tombstone table, replaced in v7 below. Raw SQL because it
        // is no longer in the schema, so there is no generated class for it —
        // but a v5 database must still walk the path v6 actually shipped.
        await customStatement(
          'CREATE TABLE IF NOT EXISTS attack_tombstones ('
          'id TEXT NOT NULL PRIMARY KEY, deleted_at INTEGER NOT NULL)',
        );
      }
      // - v7: medications and their reminders sync too, not just attacks.
      // - One tombstone table for all three replaces the attacks-only one:
      //   a tombstone holds no data, so three copies could only disagree.
      if (from < 7) {
        await m.addColumn(medications, medications.updatedAt);
        await m.addColumn(medications, medications.revision);
        await m.addColumn(medications, medications.syncedRevision);
        // Only when the reminders table predates this. `createTable` builds
        // from today's definition, so a database old enough to have run the
        // v2 step got these three columns with the table itself — adding them
        // again is a duplicate-column error.
        if (from >= 2) {
          await m.addColumn(medicationReminders, medicationReminders.updatedAt);
          await m.addColumn(medicationReminders, medicationReminders.revision);
          await m.addColumn(
            medicationReminders,
            medicationReminders.syncedRevision,
          );
        }
        await m.createTable(syncTombstones);
        // Deletions still owed to the server must survive the move, or they
        // would silently come back on the next pull.
        await customStatement(
          'INSERT INTO sync_tombstones (collection, id, deleted_at) '
          "SELECT 'attacks', id, deleted_at FROM attack_tombstones",
        );
        await customStatement('DROP TABLE IF EXISTS attack_tombstones');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
