import 'package:drift/drift.dart';

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// When the user saved this medication (UTC).
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Sync state, added in v7.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A daily local reminder to take a medication. Added in schema v2.
@DataClassName('MedicationReminderRow')
class MedicationReminders extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// Local time-of-day, stored as minutes past midnight (0–1439).
  IntColumn get minuteOfDay => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// When this reminder was created (UTC).
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Sync state, added in v7.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
