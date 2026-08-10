import '../entities/app_notification.dart';

/// The most recent pressure alert the server sent this account.
///
/// Exists because the push handler only runs with the app open: an alert
/// arriving overnight reaches the list only if the user taps the banner, or
/// if another device saw it and synced. This is the third way in.
abstract interface class LastAlertRepository {
  /// Null when there is no account, no alert has ever been sent, or the
  /// record cannot be read (offline, rules). Every one of those is a normal
  /// state, not an error — the list simply has nothing to catch up on.
  Future<AppNotification?> latest();
}
