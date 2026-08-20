import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../health/providers.dart';
import '../../../onboarding/providers.dart';
import '../../domain/entities/wipe_status.dart';
import '../../domain/services/dev_seed_service.dart';
import '../../providers.dart';

/// Orchestrates the settings actions so the widget only shows dialogs and
/// delegates. Exports live in `ExportController` — this is the GDPR wipe.
///
/// Its state is how far a wipe has got, so the Settings row can show a
/// spinner and a percentage while one runs. It lives here rather than in the
/// row because the wipe outlives no screen but does outlive a rebuild, and
/// because the dev reset runs the same wipe and gets the same indicator free.
class SettingsController extends Notifier<WipeStatus> {
  @override
  WipeStatus build() => WipeStatus.idle;

  /// GDPR wipe of all on-device data.
  ///
  /// The wipe service reports against its own steps; the Apple Health
  /// disconnect below is one more, so the bar only reaches 100% once
  /// everything is actually done.
  Future<void> deleteAll() async {
    int shownPercent = -1;

    SdLogger.action(LogTagConstant.settings, 'Delete all data (GDPR wipe)');
    AppAnalytics.logDataWiped();
    state = const WipeStatus(isRunning: true);
    try {
      await ref
          .read(dataWipeServiceProvider)
          .wipeAll(
            // Only when the whole percent moves: ten steps would otherwise
            // rebuild the row for changes it cannot show.
            onProgress: (int done, int steps) {
              final double progress = done / (steps + 1);
              final int percent = (progress * 100).round();

              if (percent == shownPercent) return;
              shownPercent = percent;
              state = WipeStatus(isRunning: true, progress: progress);
            },
          );
      // - nothing from Apple Health is stored, so there is nothing to delete
      // - but leaving it connected keeps the app reading sleep after the wipe
      await ref.read(healthControllerProvider.notifier).disconnectAll();
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

  /// Dev-only: the wipe, plus the two preference keys that make the router
  /// stop redirecting to onboarding — so the next launch behaves like a first
  /// install. No analytics event; this never runs in a build real users have.
  ///
  /// Everything `deleteAll` clears is cleared here too, deliberately: a reset
  /// that left old attacks behind would not be the first-install state it
  /// claims to be.
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

  /// Dev-only: wipes the device and refills it with sample data. No analytics
  /// event — this never runs in a build real users have.
  ///
  /// **Health is not part of it** (owner's call). HealthKit is read-only and
  /// nothing it returns is persisted (hard rule), so there is no table to
  /// fill — and the fake repository that used to stand in for it is gone: a
  /// dev build showing invented nights is harder to trust than one showing an
  /// honest empty card. Sleep and steps are checked on a device.
  Future<void> seedDevData() async {
    SdLogger.action(LogTagConstant.settings, 'Seed dev data');
    try {
      await ref.read(devSeedServiceProvider).seed();
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

}
