import '../entities/app_notification.dart';

/// Stores the notifications the user was shown.
///
/// Every write is idempotent because [AppNotification.id] is derived, so the
/// materialiser and the push handlers can all re-run without duplicating a
/// row or fighting each other.
abstract interface class NotificationRepository {
  /// Newest first — what the list screen renders.
  Stream<List<AppNotification>> watchAll();

  /// Drives the dashboard's unread dot.
  Stream<int> watchUnreadCount();

  /// Adds any of [notifications] not already stored, and **leaves rows that
  /// are** exactly as they were.
  ///
  /// Insert-if-absent, never insert-or-replace: the reminder materialiser
  /// re-derives the same occurrences on every run, and replacing would wipe
  /// [AppNotification.readAt] each time — the badge would come back every
  /// time the app opened.
  Future<void> addMissing(List<AppNotification> notifications);

  /// Marks everything unread as read at [at]. One pass rather than per row:
  /// opening the list is a single act, and the rows only differ by when they
  /// arrived.
  Future<void> markAllRead(DateTime at);

  /// GDPR wipe.
  Future<void> deleteAll();
}
