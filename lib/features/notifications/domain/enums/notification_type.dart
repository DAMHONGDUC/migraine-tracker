/// What a notification in the list was about.
///
/// Stored, so the two can be told apart after the fact — it decides what the
/// detail screen offers, never whether the row gets one. A value the build
/// does not recognise is skipped rather than guessed at, so an older build
/// pulling a newer device's rows shows fewer of them instead of mislabelling
/// one.
enum NotificationType { medicationReminder, pressureAlert }
