import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../weather/providers.dart';

/// Orchestrates onboarding: the location permission request and persisting
/// the user's choices. The screen only renders pages and calls these.
class OnboardingController {
  const OnboardingController(this._ref);

  final Ref _ref;

  static const completedKey = 'onboarding_completed';
  static const thresholdKey = 'alert_threshold';

  /// Triggers the While-Using permission prompt (reduced accuracy) by
  /// requesting one coarse fix. Best-effort: denial is fine — weather is
  /// simply skipped until the user grants it later.
  Future<void> requestLocation() async {
    try {
      await _ref.read(locationSourceProvider).currentPosition();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Location permission request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Persists the personal pressure threshold (hard rule 7: user-tunable)
  /// and marks onboarding as done so the router stops redirecting here.
  Future<void> complete({required double thresholdHpa}) async {
    final prefs = _ref.read(sharedPreferencesProvider);

    try {
      await prefs.setDouble(thresholdKey, thresholdHpa);
      await prefs.setBool(completedKey, true);
      AppAnalytics.logOnboardingCompleted(thresholdHpa: thresholdHpa);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Complete onboarding failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
