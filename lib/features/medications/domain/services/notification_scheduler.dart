import '../entities/medication_reminder.dart';

/// Schedules/cancels the OS-level daily notifications for reminders.
abstract interface class NotificationScheduler {
  /// Requests permission and prepares channels. Returns false if the user denied notifications.
  Future<bool> ensurePermission();

  /// Reminder ids from notifications tapped while the app was running.
  Stream<String> get reminderTaps;

  /// The reminder id from a notification that launched the app, or null when it was opened some other way.
  Future<String?> takeLaunchReminderId();

  /// Schedules a repeating daily notification for [reminder] using [medicationName] in the body.
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  });

  Future<void> cancel(String reminderId);

  Future<void> cancelAll();

  /// Fires a single (non-repeating) notification after [delay].
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay,
  });
}
