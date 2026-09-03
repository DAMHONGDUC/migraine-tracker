/// The kinds of record that sync, and the name each is stored under.
enum SyncCollection {
  medications('medications'),
  medicationReminders('medication_reminders'),
  attacks('attacks'),
  // Free of the ordering above: a daily log points at nothing, and nothing points at it.
  dailyLogs('daily_logs'),
  // Last: a notification points at the reminder and medication it came from, so both have to be here before it arrives.
  notifications('notifications');

  const SyncCollection(this.name);

  /// Written into Firestore paths and tombstone rows, so it must stay stable once anything has been uploaded — renaming one strands its records.
  final String name;
}
