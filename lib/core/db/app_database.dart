import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/tables/attack_tables.dart';
import '../../features/attacks/domain/enums/aura_type.dart';
import '../../features/attacks/domain/enums/exertion_level.dart';
import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/attacks/domain/enums/head_region.dart';
import '../../features/attacks/domain/enums/medication_effect.dart';
import '../../features/daily_log/data/tables/daily_log_tables.dart';
import '../../features/daily_log/domain/enums/daily_factor.dart';
import '../../features/medications/data/tables/medication_tables.dart';
import '../../features/notifications/data/tables/notification_tables.dart';
import '../../features/notifications/domain/enums/notification_type.dart';
import '../../features/settings/data/tables/export_tables.dart';
import '../../features/sync/data/tables/sync_tables.dart';
import '../../features/weather/data/tables/daily_weather_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/tables/attack_tables.dart';
export '../../features/daily_log/data/tables/daily_log_tables.dart';
export '../../features/medications/data/tables/medication_tables.dart';
export '../../features/notifications/data/tables/notification_tables.dart';
export '../../features/settings/data/tables/export_tables.dart';
export '../../features/sync/data/tables/sync_tables.dart';
export '../../features/weather/data/tables/daily_weather_tables.dart';

part 'app_database.g.dart';

/// The single on-device database. Tables are owned by their features; this class only composes them into one SQLite file.
@DriftDatabase(
  tables: [
    Attacks,
    WeatherSnapshots,
    Medications,
    MedicationReminders,
    AppNotifications,
    ExportRecords,
    SyncTombstones,
    DailyWeather,
    DailyLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: daily medication reminders.
      if (from < 2) {
        await m.createTable(medicationReminders);
      }
      // - v3: medications remember when they were added, so the tab can sort/filter by it.
      if (from < 3) {
        await m.addColumn(medications, medications.createdAt);
      }
      // - v4: the export screen keeps a history. - Nothing to backfill — exports before this shipped were never recorded.
      if (from < 4) {
        await m.createTable(exportRecords);
      }
      // - v5: self-reported physical exertion, added to the details step. - Existing rows get null — nobody reported exertion before this shipped.
      if (from < 5) {
        await m.addColumn(attacks, attacks.exertionLevel);
      }
      // - v6: sync state per attack, for encrypted upload once signed in.
      if (from < 6) {
        await m.addColumn(attacks, attacks.updatedAt);
        await m.addColumn(attacks, attacks.revision);
        await m.addColumn(attacks, attacks.syncedRevision);
        // v6's own tombstone table, replaced in v7 below.
        await customStatement(
          'CREATE TABLE IF NOT EXISTS attack_tombstones ('
          'id TEXT NOT NULL PRIMARY KEY, deleted_at INTEGER NOT NULL)',
        );
      }
      // - v7: medications and their reminders sync too, not just attacks.
      if (from < 7) {
        await m.addColumn(medications, medications.updatedAt);
        await m.addColumn(medications, medications.revision);
        await m.addColumn(medications, medications.syncedRevision);
        // Only when the reminders table predates this: `createTable` builds from today's definition, so a database that ran the v2 step already has these.
        if (from >= 2) {
          await m.addColumn(medicationReminders, medicationReminders.updatedAt);
          await m.addColumn(medicationReminders, medicationReminders.revision);
          await m.addColumn(
            medicationReminders,
            medicationReminders.syncedRevision,
          );
        }
        await m.createTable(syncTombstones);
        // Deletions still owed to the server must survive the move, or they would silently come back on the next pull.
        await customStatement(
          'INSERT INTO sync_tombstones (collection, id, deleted_at) '
          "SELECT 'attacks', id, deleted_at FROM attack_tombstones",
        );
        await customStatement('DROP TABLE IF EXISTS attack_tombstones');
      }
      // - v8: the notification list, and the bound its reminder half needs.
      if (from < 8) {
        await m.createTable(appNotifications);
        // Same guard as v7's: `createTable` builds from today's definition, so a database young enough to have just run the v2 step already has this column.
        if (from >= 2) {
          await m.addColumn(medicationReminders, medicationReminders.createdAt);
        }
      }
      // - v9: `type` was `kind` in a dev-only v8, renamed in place — those databases sit at v8 with the old column and no step that fixes it.
      if (from < 9) {
        await customStatement('DROP TABLE IF EXISTS app_notifications');
        await m.createTable(appNotifications);
      }
      // - v10: how long an attack lasted, recorded after the fact.
      if (from < 10) {
        await m.addColumn(attacks, attacks.endedAt);
      }
      // - v11: whether the medication taken for an attack helped.
      if (from < 11) {
        await m.addColumn(attacks, attacks.medicationEffect);
      }
      // - v12: a pressure reading per day, so the correlation has a denominator — the days without an attack.
      if (from < 12) {
        await m.createTable(dailyWeather);
      }
      // - v13: the location step records a SET of head areas, so `location` becomes `regions`.
      if (from < 13) {
        await m.addColumn(attacks, attacks.regions);
        for (final HeadLocation location in HeadLocation.values) {
          await customUpdate(
            'UPDATE attacks SET regions = ? WHERE location = ?',
            variables: <Variable<Object>>[
              Variable<String>(
                const HeadRegionListConverter().toSql(location.regions),
              ),
              Variable<String>(location.name),
            ],
            updates: <TableInfo<Table, Object?>>{attacks},
          );
        }
        // Recreates the table from today's definition, which no longer has `location` — drift's way of dropping a column SQLite cannot drop.
        await m.alterTable(
          TableMigration(
            attacks,
            newColumns: <GeneratedColumn<Object>>[
              attacks.steps,
              attacks.aura,
              attacks.medicationTakenAt,
              attacks.reliefAt,
            ],
          ),
        );
      }
      // - v14: an attack carries the day's step count, read as it was logged.
      if (from >= 13 && from < 14) {
        await m.addColumn(attacks, attacks.steps);
      }
      // - v15: the aura kinds reported for an attack, recorded after the fact.
      if (from >= 13 && from < 15) {
        await m.addColumn(attacks, attacks.aura);
      }
      // - v16 is deliberately empty: an unshipped v16 ran on a dev device with a different meaning, and a device that took it would skip a step numbered the same.
      // - v17: the daily check-in, which gives every analysis the days without an attack to compare against.
      if (from < 17) {
        await m.createTable(dailyLogs);
      }
      // - v18: when the medication was taken and when the pain eased, so "did it help" can become "in how long". Only a database already at 13 or later needs these: v13's rebuild creates them from today's definition.
      if (from >= 13 && from < 18) {
        await m.addColumn(attacks, attacks.medicationTakenAt);
        await m.addColumn(attacks, attacks.reliefAt);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
