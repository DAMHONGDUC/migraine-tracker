import '../entities/app_notification.dart';

/// Stores the notifications the user was shown.
abstract interface class NotificationRepository {
  /// Newest first — what the list screen renders.
  Stream<List<AppNotification>> watchAll();

  /// Drives the dashboard's badge — how many rows the user has not opened the detail of yet.
  Stream<int> watchUnreadCount();

  /// Adds any of [notifications] not already stored, and leaves rows that are exactly as they were.
  Future<void> addMissing(List<AppNotification> notifications);

  /// The newest occurrence of one reminder, or null when none has been derived yet.
  Future<AppNotification?> latestForReminder(String reminderId);

  /// The newest pressure alert on record, or null when none ever arrived.
  Future<AppNotification?> latestPressureAlert();

  /// Marks one notification read at [at].
  Future<void> markRead(String id, DateTime at);

  /// GDPR wipe.
  Future<void> deleteAll();
}
