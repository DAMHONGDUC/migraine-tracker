/// The kinds of record that sync, and the name each is stored under —
/// remotely as a top-level Firestore collection, locally as the discriminator
/// on the tombstone table.
///
/// Every value must be named in `firestore.rules` and carry its composite
/// index in `firestore.indexes.json`; `sync_collection_rules_test.dart` fails
/// when they drift.
///
/// Order is load-bearing: a reminder points at a medication, so medications
/// must arrive before the reminders that reference them, or the pull hits a
/// foreign key that is not there yet.
enum SyncCollection {
  medications('medications'),
  medicationReminders('medication_reminders'),
  attacks('attacks'),
  // Last: a notification points at the reminder and medication it came
  // from, so both have to be here before it arrives.
  notifications('notifications');

  const SyncCollection(this.name);

  /// Written into Firestore paths and tombstone rows, so it must stay stable
  /// once anything has been uploaded — renaming one strands its records.
  final String name;
}
