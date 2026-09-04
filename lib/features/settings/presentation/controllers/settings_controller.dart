import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../daily_log/providers.dart';
import '../../../health/providers.dart';
import '../../../onboarding/providers.dart';
import '../../../weather/providers.dart';
import '../../domain/entities/wipe_status.dart';
import '../../domain/services/dev_seed_service.dart';
import '../../providers.dart';

/// Orchestrates the settings actions so the widget only shows dialogs and delegates.
class SettingsController extends Notifier<WipeStatus> {
  @override
  WipeStatus build() => WipeStatus.idle;

  /// GDPR wipe of all on-device data.
  Future<void> deleteAll() async {
    int shownPercent = -1;

    SdLogger.action(LogTagConstant.settings, 'Delete all data (GDPR wipe)');
    AppAnalytics.logDataWiped();
    state = const WipeStatus(isRunning: true);
    try {
      await ref
          .read(dataWipeServiceProvider)
          .wipeAll(
            // Only when the whole percent moves: ten steps would otherwise rebuild the row for changes it cannot show.
            onProgress: (int done, int steps) {
              final double progress = done / (steps + 1);
              final int percent = (progress * 100).round();

              if (percent == shownPercent) return;
              shownPercent = percent;
              state = WipeStatus(isRunning: true, progress: progress);
            },
          );
      // - nothing from Apple Health is stored, so there is nothing to delete - but leaving it connected keeps the app reading sleep after the wipe
      await ref.read(healthControllerProvider.notifier).disconnectAll();
      _refreshStoredData();
      state = const WipeStatus(isRunning: true, progress: 1);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.settings,
        'Delete all data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      state = WipeStatus.idle;
    }
  }

  /// Dev-only: the wipe, plus the two preference keys that make the router stop redirecting to onboarding — so the next launch behaves like a first install.
  Future<void> resetToOnboarding() async {
    SdLogger.action(LogTagConstant.settings, 'Reset to onboarding (dev)');
    try {
      await deleteAll();
      await ref.read(onboardingControllerProvider).reset();
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
      await ref.read(devSeedServiceProvider).seed();
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

  /// Re-reads the stored data that nothing else will re-read on its own, after a wipe or a seed has replaced all of it.
  ///
  /// Every other list on the screen hangs off a Drift `watch`, which emits on the write itself. These three are one-shot reads, so a
  /// wipe or a seed leaves them holding rows that no longer exist until the next launch — which is what "I have to restart to see the
  /// sample data" was. The insights built on them (`factorMapProvider`, `riskForecastProvider`) recompute on their own once these do.
  void _refreshStoredData() {
    SdLogger.info(LogTagConstant.settings, 'Refresh stored-data providers');
    ref
      ..invalidate(recentDailyLogsProvider)
      ..invalidate(answeredDailyLogCountProvider)
      ..invalidate(dailyPressureHistoryProvider);
  }
}
