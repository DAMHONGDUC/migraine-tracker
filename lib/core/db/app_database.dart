import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/tables/attack_tables.dart';
import '../../features/attacks/domain/enums/head_location.dart';
import '../../features/medications/data/tables/medication_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/tables/attack_tables.dart';
export '../../features/medications/data/tables/medication_tables.dart';

part 'app_database.g.dart';

/// The single on-device database. Tables are owned by their features; this
/// class only composes them into one SQLite file.
@DriftDatabase(
  tables: [Attacks, WeatherSnapshots, Medications, MedicationReminders],
)
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 3;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
