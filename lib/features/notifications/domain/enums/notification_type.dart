/// What a notification in the list was about.
///
/// Stored, so the two can be told apart after the fact — a medication
/// row opens its medication, a pressure row opens an info sheet. A value the
/// build does not recognise is skipped rather than guessed at, so an older
/// build pulling a newer device's rows shows fewer of them instead of
/// mislabelling one.
enum NotificationType { medicationReminder, pressureAlert }
