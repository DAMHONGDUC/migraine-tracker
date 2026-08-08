import '../entities/medication_reminder.dart';

/// Schedules/cancels the OS-level daily notifications for reminders.
/// Kept behind an interface so the reminder logic is testable without the
/// flutter_local_notifications plugin.
abstract interface class NotificationScheduler {
  /// Requests permission and prepares channels. Returns false if the user
  /// denied notifications.
  Future<bool> ensurePermission();

  /// Reminder ids from notifications tapped while the app was running.
  ///
  /// The id alone, not an occurrence: the OS says which reminder fired and
  /// when the user answered it, and the app resolves that to a row itself.
  Stream<String> get reminderTaps;

  /// The reminder id from a notification that launched the app, or null when
  /// it was opened some other way.
  ///
  /// Takes it: the launch details survive for the life of the process, so a
  /// second read would open the same screen again on the next resume.
  Future<String?> takeLaunchReminderId();

  /// Schedules a repeating daily notification for [reminder] using
  /// [medicationName] in the body. Cancels any existing one with the same id.
  ///
  /// Always audible: there is no app-level mute, because the OS already owns
  /// that switch.
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  });

  Future<void> cancel(String reminderId);

  Future<void> cancelAll();

  /// Fires a single (non-repeating) notification after [delay] — a debug-only
  /// smoke test so a developer can confirm notifications actually deliver
  /// without waiting for a real reminder time. Requests permission first.
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay,
  });
}
