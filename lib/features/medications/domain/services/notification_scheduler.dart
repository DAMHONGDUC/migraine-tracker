import '../entities/medication_reminder.dart';

/// Schedules/cancels the OS-level daily notifications for reminders.
/// Kept behind an interface so the reminder logic is testable without the
/// flutter_local_notifications plugin.
abstract interface class NotificationScheduler {
  /// Requests permission and prepares channels. Returns false if the user
  /// denied notifications.
  Future<bool> ensurePermission();

  /// Schedules a repeating daily notification for [reminder] using
  /// [medicationName] in the body. Cancels any existing one with the same id.
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  });

  Future<void> cancel(String reminderId);

  Future<void> cancelAll();
}
