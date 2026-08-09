import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/repositories/last_alert_repository.dart';

/// Stands in for the `users/{uid}` read the launch reconcile does, which
/// otherwise reaches Firebase in every widget test.
///
/// Defaults to "nothing to catch up on" — the ordinary case — so a test only
/// passes an alert when it is testing the reconcile itself.
class FakeLastAlertRepository implements LastAlertRepository {
  FakeLastAlertRepository({this.alert});

  /// Returned by every call; null is an account with no alert on record.
  AppNotification? alert;

  int calls = 0;

  @override
  Future<AppNotification?> latest() async {
    calls++;
    return alert;
  }
}

/// The failing half: offline, or rules refusing the read. The reconcile must
/// swallow it — a missed row is never a reason to break launching the app.
class ThrowingLastAlertRepository implements LastAlertRepository {
  @override
  Future<AppNotification?> latest() async =>
      throw StateError('last alert unavailable');
}
