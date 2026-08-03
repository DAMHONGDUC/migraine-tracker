import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/tables/attack_tables.dart';
import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/medications/data/tables/medication_tables.dart';
import '../../features/settings/data/tables/export_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/tables/attack_tables.dart';
export '../../features/medications/data/tables/medication_tables.dart';
export '../../features/settings/data/tables/export_tables.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: daily medication reminders.
      if (from < 2) {
        await m.createTable(medicationReminders);
      }
      // v3: medications remember when they were added, so the medications
      // tab can sort and filter by it. Existing rows get null — their real
      // creation date was never recorded and inventing one would corrupt
      // the very filter this column exists to serve.
      if (from < 3) {
        await m.addColumn(medications, medications.createdAt);
      }
      // v4: the export screen keeps a history. Nothing to backfill —
      // exports made before this shipped were never recorded.
      if (from < 4) {
        await m.createTable(exportRecords);
      }
      // v5: a medication can carry what its box says. Every column is
      // nullable and stays null for existing rows — nothing to backfill,
      // and null is exactly what "the user never told us" means.
      if (from < 5) {
        await m.addColumn(medications, medications.description);
        await m.addColumn(medications, medications.ingredients);
        await m.addColumn(medications, medications.strength);
        await m.addColumn(medications, medications.dosage);
        await m.addColumn(medications, medications.instructions);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
