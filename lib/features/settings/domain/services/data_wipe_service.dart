import '../../../alerts/domain/repositories/alert_registration_repository.dart';
import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home_widget/domain/repositories/home_widget_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../medications/domain/services/notification_scheduler.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../sync/domain/services/sync_service.dart';
import '../../../weather/domain/repositories/daily_pressure_repository.dart';
import '../repositories/export_record_repository.dart';
import 'export_file_store.dart';

/// How far the wipe has got, as completed steps out of the total.
typedef WipeProgressCallback = void Function(int done, int steps);

/// GDPR "delete everything" (hard rule 8): the on-device database, past
/// exports, and the account's synced copy.
///
/// Keeps the account: this clears what the user put in, not who they are.
/// Deleting the account is its own action (`deleteAccount`), because someone
/// clearing their history usually wants to carry on using the app — and
/// losing the account would unbind their subscription with it.
class DataWipeService {
  const DataWipeService(
    this._attacks,
    this._medications,
    this._notifications,
    this._notificationList,
    this._exportRecords,
    this._exportFiles,
    this._auth,
    this._sync,
    this._alerts,
    this._dailyPressure,
    this._homeWidget,
  );

  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final NotificationScheduler _notifications;

  /// The notification LIST, as opposed to the OS scheduler above — two
  /// different things, and both have to go (hard rule 8).
  final NotificationRepository _notificationList;
  final ExportRecordRepository _exportRecords;
  final ExportFileStore _exportFiles;
  final AuthRepository _auth;
  final SyncService _sync;
  final AlertRegistrationRepository _alerts;
  final DailyPressureRepository _dailyPressure;

  /// The App Group the home-screen widget reads. Not a database, but a copy
  /// of the user's data all the same — and the only one still on screen
  /// after the wipe if it is left behind.
  final HomeWidgetRepository _homeWidget;

  /// How many awaits [wipeAll] reports against. Counted here rather than
  /// derived, because the order below is the rule and a step must never be
  /// silently added without the count moving with it.
  static const int steps = 10;

  /// [onProgress] fires after each step with how many are done out of
  /// [steps]. Fixed steps, never records: counting rows would mean
  /// discovering more work mid-wipe, and a bar that jumps backwards reads as
  /// a bug even when the wipe is fine (the same rule sync's bar follows).
  Future<void> wipeAll({WipeProgressCallback? onProgress}) async {
    int done = 0;

    void step() => onProgress?.call(++done, steps);

    onProgress?.call(0, steps);
    // The server copy goes FIRST, and a failure here aborts the whole wipe:
    // wiping the device first leaves the cloud history with nothing left to
    // say it should go, and the next sync pulls it all back down.
    await _wipeRemote();
    step();

    // Before the local data, because this is the one thing that can still
    // reach the user after the wipe: leave the FCM token behind and the cron
    // keeps pushing pressure alerts to a device with nothing left in it.
    await _alerts.forgetRegistration();
    step();

    await _attacks.deleteAll();
    step();
    // DB cascade drops reminder rows but never reaches the OS — cancel or a notification keeps firing.
    await _notifications.cancelAll();
    step();
    await _medications.deleteAll();
    step();
    // Derived from the reminders, but stored: leave them and the list
    // still names medications the user just deleted.
    await _notificationList.deleteAll();
    step();
    // Past exports are full copies of the deleted data — leave them and the wipe is incomplete.
    await _exportFiles.deleteAll();
    step();
    await _exportRecords.deleteAll();
    step();
    // Never synced, but still the user's: a per-day pressure trail is a
    // record of where they were (hard rule 1), so it goes with everything
    // else rather than surviving a "delete all data".
    await _dailyPressure.deleteAll();
    step();
    // Last, because it is derived from everything above: emptied any earlier
    // and the next redraw would put the old numbers straight back.
    await _homeWidget.clear();
    step();
  }

  /// Nothing to do without an account: an anonymous session never uploaded
  /// anything, so there is no server copy to chase.
  Future<void> _wipeRemote() async {
    final AuthUser? user = _auth.currentUser;

    if (user == null || !user.isSignedIn) return;
    await _sync.wipeRemote(user.uid);
  }
}
