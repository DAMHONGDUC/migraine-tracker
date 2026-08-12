import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../health/domain/enums/health_data_kind.dart';
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

    AppLogger.action('Delete all data (GDPR wipe)');
    AppAnalytics.logDataWiped();
    state = const WipeStatus(isRunning: true);
    try {
      await ref.read(dataWipeServiceProvider).wipeAll(
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
      // Dev-only, and nothing real is lost — but "delete everything" that
      // leaves invented health data still generating is a lie about what it
      // did. No extra step: this rides the disconnect above.
      await ref.read(devHealthSeedProvider.notifier).clear();
      state = const WipeStatus(isRunning: true, progress: 1);
    } catch (error, stackTrace) {
      AppLogger.error(
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
    AppLogger.action('Reset to onboarding (dev)');
    try {
      await deleteAll();
      await ref.read(onboardingControllerProvider).reset();
    } catch (error, stackTrace) {
      AppLogger.error(
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
  /// Health is seeded here rather than inside `DevSeedService`, because it is
  /// not a table: HealthKit is read-only and nothing it returns is persisted
  /// (hard rule), so "seeding" it means switching the dev fake on and
  /// connecting both sources — the reads then generate from the seed.
  Future<void> seedDevData() async {
    AppLogger.action('Seed dev data');
    try {
      await ref.read(devSeedServiceProvider).seed();
      await _seedHealth();
      AppLogger.info('Seed dev data done', DevSeedService.seedCount);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Seed dev data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Points the health repository at the dev fake and marks both sources
  /// connected, so the sleep and activity cards have something to draw on a
  /// Simulator — where real HealthKit reads always come back empty.
  Future<void> _seedHealth() async {
    await ref
        .read(devHealthSeedProvider.notifier)
        .set(DateTime.now().millisecondsSinceEpoch);

    // After the seed, so `connect` asks the fake rather than the plugin.
    for (final HealthDataKind kind in HealthDataKind.values) {
      await ref.read(healthControllerProvider.notifier).connect(kind);
    }
  }

}
