import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../daily_log/providers.dart';
import '../../../health/providers.dart';
import '../../../onboarding/providers.dart';
import '../../../weather/providers.dart';
import '../../domain/services/dev_seed_service.dart';
import '../../providers.dart';

/// Orchestrates the settings actions so the widget only shows dialogs and delegates.
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  /// Dev-only: the wipe, plus the two preference keys that make the router stop redirecting to onboarding — so the next launch behaves like a first install.
  Future<void> resetToOnboarding() async {
    SdLogger.action(LogTagConstant.settings, 'Reset to onboarding (dev)');
    try {
      await deleteAllData();
      await _ref.read(onboardingControllerProvider).reset();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.settings,
        'Reset to onboarding failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Dev-only: wipes the device and refills it with sample data.
  Future<void> seedDevData() async {
    SdLogger.action(LogTagConstant.settings, 'Seed dev data');
    try {
      await _ref.read(devSeedServiceProvider).seed();
      _refreshStoredData();
      SdLogger.info(
        LogTagConstant.settings,
        'Seed dev data done',
        <String, Object?>{
          'attacks': DevSeedService.attackCount,
          'medications': DevSeedService.medicationCount,
          'reminders': DevSeedService.reminderCount,
          'exports': DevSeedService.exportCount,
        },
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.settings,
        'Seed dev data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Everything on the device and the account's synced copy, gone — without touching onboarding, so the app stays where it is and comes back empty.
  ///
  /// Dev-only: the user-facing teardown is "Delete account" (`AccountController`). [resetToOnboarding] is this plus the onboarding flags.
  Future<void> deleteAllData() async {
    SdLogger.action(LogTagConstant.settings, 'Delete all data (dev)');
    try {
      await _ref.read(dataWipeServiceProvider).wipeAll();
      // - nothing from Apple Health is stored, so there is nothing to delete - but leaving it connected keeps the app reading sleep after the wipe
      await _ref.read(healthControllerProvider.notifier).disconnectAll();
      _refreshStoredData();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.settings,
        'Delete all data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Re-reads the stored data that nothing else will re-read on its own, after a wipe or a seed has replaced all of it.
  ///
  /// Every other list on the screen hangs off a Drift `watch`, which emits on the write itself. These three are one-shot reads, so a
  /// wipe or a seed leaves them holding rows that no longer exist until the next launch — which is what "I have to restart to see the
  /// sample data" was. The insights built on them (`factorMapProvider`, `riskForecastProvider`) recompute on their own once these do.
  void _refreshStoredData() {
    SdLogger.info(LogTagConstant.settings, 'Refresh stored-data providers');
    _ref
      ..invalidate(recentDailyLogsProvider)
      ..invalidate(answeredDailyLogCountProvider)
      ..invalidate(dailyPressureHistoryProvider);
  }
}
