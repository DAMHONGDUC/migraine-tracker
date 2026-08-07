/// The kinds of record that sync, and the name each is stored under —
/// remotely as a Firestore subcollection, locally as the discriminator on the
/// tombstone table.
///
/// Order is load-bearing: a reminder points at a medication, so medications
/// must arrive before the reminders that reference them, or the pull hits a
/// foreign key that is not there yet.
enum SyncCollection {
  medications('medications'),
  medicationReminders('medication_reminders'),
  attacks('attacks');

  const SyncCollection(this.name);

  /// Written into Firestore paths and tombstone rows, so it must stay stable
  /// once anything has been uploaded — renaming one strands its records.
  final String name;
}
