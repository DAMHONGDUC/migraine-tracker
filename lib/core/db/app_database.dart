import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/attacks/data/attack_tables.dart';
import '../../features/attacks/domain/head_location.dart';
import '../../features/medications/data/medication_tables.dart';
import 'converters.dart';

export '../../features/attacks/data/attack_tables.dart';
export '../../features/medications/data/medication_tables.dart';

part 'app_database.g.dart';

/// The single on-device database. Tables are owned by their features; this
/// class only composes them into one SQLite file.
@DriftDatabase(tables: [Attacks, WeatherSnapshots, Medications])
class AppDatabase extends _$AppDatabase {
  /// Test constructor — pass e.g. `NativeDatabase.memory()`.
  AppDatabase(super.e);

  /// Opens the on-device database. Source of truth for all health data.
  AppDatabase.open() : super(driftDatabase(name: 'baroease'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
