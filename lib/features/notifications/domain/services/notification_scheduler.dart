import '../../../medications/domain/entities/medication_reminder.dart';

/// Schedules/cancels the OS-level local notifications.
///
/// It lives in `notifications/` rather than in `medications/` because two
/// features schedule now: a medication reminder, and the daily check-in
/// (`lib/features/daily_log/CLAUDE.md`). `daily_log` may not reach into
/// another feature's `data/`, which is what forced the move.
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

  /// Schedules the ONE next check-in nudge, at [when]. Never repeating, unlike a medication reminder.
  ///
  /// A repeat would fire on a day already answered; the app instead re-arms
  /// this after every check-in and on every resume, so the nudge exists only
  /// while the day it asks about is still unanswered.
  Future<void> scheduleCheckIn({
    required DateTime when,
    required String title,
    required String body,
  });

  Future<void> cancelCheckIn();

  /// Fires a single (non-repeating) notification after [delay].
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay,
  });
}
