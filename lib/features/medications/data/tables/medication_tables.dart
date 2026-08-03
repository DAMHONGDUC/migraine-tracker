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

  /// Everything the details form collects, added in schema v5. All nullable
  /// and all free text: only the name is ever required, and a medicine box
  /// writes its strength and dosage in too many shapes to structure. Null
  /// means "not filled in" — an empty string would print an empty row.
  TextColumn get description => text().nullable()();
  TextColumn get ingredients => text().nullable()();
  TextColumn get strength => text().nullable()();
  TextColumn get dosage => text().nullable()();
  TextColumn get instructions => text().nullable()();

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
