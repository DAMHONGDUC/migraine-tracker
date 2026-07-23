import 'package:drift/drift.dart';

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// When the user saved this medication (UTC). Added in schema v3 to sort
  /// and filter the medications tab.
  ///
  /// Nullable on purpose: rows that predate v3 have no recorded creation
  /// date and stamping them with the migration's timestamp would invent one
  /// — "added this week" would then list medications saved years ago. Null
  /// means "unknown", sorts last, and matches only the "all" filter.
  DateTimeColumn get createdAt => dateTime().nullable()();

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

  @override
  Set<Column<Object>> get primaryKey => {id};
}
