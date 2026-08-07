import '../entities/app_notification.dart';

/// Stores the notifications the user was shown.
///
/// Every write is idempotent because [AppNotification.id] is derived, so the
/// materialiser and the push handlers can all re-run without duplicating a
/// row or fighting each other.
abstract interface class NotificationRepository {
  /// Newest first — what the list screen renders.
  Stream<List<AppNotification>> watchAll();

  /// Drives the dashboard's badge — how many the user has not opened the
  /// list for yet.
  Stream<int> watchUnreadCount();

  /// Adds any of [notifications] not already stored, and **leaves rows that
  /// are** exactly as they were.
  ///
  /// Insert-if-absent, never insert-or-replace: the reminder materialiser
  /// re-derives the same occurrences on every run, and replacing would wipe
  /// [AppNotification.readAt] each time — the badge would come back every
  /// time the app opened.
  Future<void> addMissing(List<AppNotification> notifications);

  /// Marks one notification read at [at].
  ///
  /// Per row, not per screen: opening the list is not reading anything, so
  /// the unread dot on a row means what it says and the bell's count comes
  /// down one at a time as they are opened.
  ///
  /// A no-op for a row already read, so re-entering a detail screen does
  /// not bump its revision and push it again.
  Future<void> markRead(String id, DateTime at);

  /// GDPR wipe.
  Future<void> deleteAll();
}
