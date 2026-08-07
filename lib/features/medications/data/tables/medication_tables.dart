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

  /// Sync state, added in v7. Same three columns and same reasoning as
  /// `Attacks`: a revision decides what is dirty because drift stores dates
  /// to the second, and [updatedAt] only settles which device's version wins.
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

  /// When this reminder was created (UTC). Added in schema v8, and it syncs:
  /// the notification list materialises past occurrences over a window, and
  /// without a lower bound it would invent months of "you were reminded" for
  /// a reminder created yesterday. Every device has to agree where that
  /// history starts, which is why it travels in the payload.
  ///
  /// Nullable for the same reason `Medications.createdAt` is: rows that
  /// predate v8 have no recorded creation date, and stamping them with the
  /// migration's timestamp would invent the very bound this exists to give.
  /// Null means "unknown" and the window alone bounds them.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Sync state, added in v7. Note what syncs and what does not: the row
  /// travels, the scheduled OS notification does not — it is local to each
  /// device and gets re-scheduled after a pull.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
