import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../alerts/domain/repositories/alert_registration_repository.dart';
import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../attacks/domain/services/attack_live_activity.dart';
import '../../../attacks/domain/services/attack_share_file_store.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../daily_log/domain/repositories/daily_log_repository.dart';
import '../../../home_widget/domain/repositories/home_widget_repository.dart';
import '../../../insights/domain/repositories/midas_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../notifications/domain/services/notification_scheduler.dart';
import '../../../sync/domain/services/sync_service.dart';
import '../../../weather/domain/repositories/daily_pressure_repository.dart';
import '../repositories/export_record_repository.dart';
import 'export_file_store.dart';

/// How far the wipe has got, as completed steps out of the total.
typedef WipeProgressCallback = void Function(int done, int steps);

/// GDPR "delete everything" (hard rule 8): the on-device database, past exports, the share images, and the account's synced copy.
///
/// Reached by account deletion and the three dev tiles — the user-facing Settings row that used to call it was removed (owner's call, 2026-09-05).
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
    this._dailyLogs,
    this._midas,
    this._shareFiles,
    this._homeWidget,
    this._liveActivity, {
    this.remoteTimeout = const Duration(seconds: 60),
  });

  /// How long each of the two network steps may take before the wipe gives up.
  ///
  /// A Firestore write's future settles only once the server acknowledges it,
  /// so an unreachable backend leaves a bare `await` pending for as long as the
  /// app runs — which is what left the three dev tiles spinning with no error
  /// and no way out. Both network steps run before anything local is touched,
  /// so giving up here aborts with the device's copy still whole (hard rule 8).
  ///
  /// A parameter only so a test need not wait out the real minute.
  final Duration remoteTimeout;

  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final NotificationScheduler _notifications;

  /// The notification LIST, as opposed to the OS scheduler above — two different things, and both have to go (hard rule 8).
  final NotificationRepository _notificationList;
  final ExportRecordRepository _exportRecords;
  final ExportFileStore _exportFiles;
  final AuthRepository _auth;
  final SyncService _sync;
  final AlertRegistrationRepository _alerts;
  final DailyPressureRepository _dailyPressure;

  /// The daily check-ins. Synced like an attack, so the remote half above takes the server's copy and this takes the device's.
  final DailyLogRepository _dailyLogs;

  /// The MIDAS answers. Synced like the rest, so the remote half above takes the server's copy and this takes the device's.
  final MidasRepository _midas;

  /// The share images. Not a database and not listed anywhere in the app, but a copy of the user's health data on disk all the same.
  final AttackShareFileStore _shareFiles;

  /// The App Group the home-screen widget reads.
  final HomeWidgetRepository _homeWidget;

  /// The Lock Screen card. Not a database and not on disk, but the user's health data on a screen anyone can see (hard rule 8).
  final AttackLiveActivity _liveActivity;

  /// How many awaits [wipeAll] reports against.
  static const int steps = 14;

  /// The device-only half of [steps] — what [wipeLocal] reports against.
  static const int localSteps = 12;

  /// [onProgress] fires after each step with how many are done out of [steps].
  ///
  /// Every step also logs, because this runs behind a spinner with nothing else
  /// on screen: without a line per step, a wipe that stalls names no suspect.
  Future<void> wipeAll({WipeProgressCallback? onProgress}) async {
    int done = 0;

    void step(String what) {
      onProgress?.call(++done, steps);
      SdLogger.info(LogTagConstant.settings, 'Wipe $done/$steps', what);
    }

    onProgress?.call(0, steps);
    // The server copy goes FIRST, and a failure here aborts the whole wipe.
    await _wipeRemote().timeout(remoteTimeout);
    step('synced records');

    // Before the local data, because this is the one thing that can still reach the user after the wipe: leave the FCM token behind and the cron keeps.
    await _alerts.forgetRegistration().timeout(remoteTimeout);
    step('alert registration');

    await _wipeLocalData(step);
  }

  /// The device's copy alone — the account's server copy is left where it is.
  ///
  /// What signing out takes with it. The records are being handed back to the
  /// account rather than deleted, so this must never reach [_wipeRemote]: the
  /// next sign-in pulls the whole history down again, and a sign-out that
  /// emptied the server would make that a one-way trip.
  ///
  /// It takes the exports and the share images too. They are copies of the
  /// account's health data sitting in the app's own storage with nothing
  /// naming who they belong to, and the next person to use this device is not
  /// necessarily the one who made them. A file the user saved out to Files is
  /// theirs and is not touched.
  Future<void> wipeLocal({WipeProgressCallback? onProgress}) async {
    int done = 0;

    void step(String what) {
      onProgress?.call(++done, localSteps);
      SdLogger.info(
        LogTagConstant.settings,
        'Local wipe $done/$localSteps',
        what,
      );
    }

    onProgress?.call(0, localSteps);
    await _wipeLocalData(step);
  }

  /// The twelve device-side steps both wipes share, counted by the caller's [step].
  Future<void> _wipeLocalData(void Function(String what) step) async {
    await _attacks.deleteAll();
    step('attacks');
    // DB cascade drops reminder rows but never reaches the OS — cancel or a notification keeps firing.
    await _notifications.cancelAll();
    step('scheduled notifications');
    await _medications.deleteAll();
    step('medications');
    // Derived from the reminders, but stored: leave them and the list still names medications the user just deleted.
    await _notificationList.deleteAll();
    step('notification list');
    // Past exports are full copies of the deleted data — leave them and the wipe is incomplete.
    await _exportFiles.deleteAll();
    step('export files');
    await _exportRecords.deleteAll();
    step('export records');
    // Never synced, but still the user's.
    await _dailyPressure.deleteAll();
    step('pressure readings');
    // How the user slept and how stressed they were, on every day they answered.
    await _dailyLogs.deleteAll();
    step('daily check-ins');
    // How many days migraine cost them, in their own words.
    await _midas.deleteAll();
    step('MIDAS answers');
    // A shared attack is written to temporary storage for the share sheet to read.
    await _shareFiles.deleteAll();
    step('share images');
    // Before the widget, because both draw from what is now gone.
    await _liveActivity.end();
    step('live activity');
    // Last, because it is derived from everything above: emptied any earlier and the next redraw would put the old numbers straight back.
    await _homeWidget.clear();
    step('home widget');
  }

  /// Nothing to do without an account: an anonymous session never uploaded anything, so there is no server copy to chase.
  Future<void> _wipeRemote() async {
    final AuthUser? user = _auth.currentUser;

    if (user == null || !user.isSignedIn) return;
    await _sync.wipeRemote(user.uid);
  }
}
