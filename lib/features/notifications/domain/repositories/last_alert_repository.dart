import '../entities/app_notification.dart';

/// The most recent pressure alert the server sent this account.
abstract interface class LastAlertRepository {
  /// Null when there is no account, no alert has ever been sent, or the record cannot be read (offline, rules).
  Future<AppNotification?> latest();
}
