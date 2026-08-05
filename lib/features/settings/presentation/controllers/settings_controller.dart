import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../health/providers.dart';
import '../../../onboarding/providers.dart';
import '../../providers.dart';

/// Orchestrates the settings actions so the widget only shows dialogs and
/// delegates. Exports live in `ExportController` — this is the GDPR wipe.
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  /// GDPR wipe of all on-device data.
  Future<void> deleteAll() async {
    AppLogger.action('Delete all data (GDPR wipe)');
    AppAnalytics.logDataWiped();
    try {
      await _ref.read(dataWipeServiceProvider).wipeAll();
      // - nothing from Apple Health is stored, so there is nothing to delete
      // - but leaving it connected keeps the app reading sleep after the wipe
      await _ref.read(healthControllerProvider.notifier).disconnect();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete all data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
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
      await _ref.read(onboardingControllerProvider).reset();
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
  Future<void> seedDevData() async {
    AppLogger.action('Seed dev data');
    try {
      await _ref.read(devSeedServiceProvider).seed();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Seed dev data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
