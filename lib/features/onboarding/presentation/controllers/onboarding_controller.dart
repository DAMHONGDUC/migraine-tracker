import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../weather/providers.dart';

/// Orchestrates onboarding: the location permission request and persisting the user's choices. The screen only renders pages and calls these.
class OnboardingController {
  const OnboardingController(this._ref);

  final Ref _ref;

  /// Raises the While-Using prompt (reduced accuracy).
  Future<void> requestLocation() async {
    try {
      await _ref.read(locationSourceProvider).requestPermission();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.onboarding,
        'Location permission request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Forgets that onboarding was ever done, so the router redirects here again on the next frame.
  Future<void> reset() async {
    final prefs = _ref.read(secureStoreProvider);

    try {
      await prefs.remove(PrefsKeyConstant.onboardingCompleted);
      await prefs.remove(PrefsKeyConstant.alertThreshold);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.onboarding,
        'Reset onboarding failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Raises the notification prompt, once, at the end of onboarding.
  Future<void> requestNotifications() async {
    try {
      await _ref
          .read(appPermissionProvider)
          .request(AppPermissionType.notification);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.onboarding,
        'Notification permission request failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Persists the personal pressure threshold (hard rule 7: user-tunable) and marks onboarding as done so the router stops redirecting here.
  Future<void> complete({required double thresholdHpa}) async {
    final prefs = _ref.read(secureStoreProvider);

    try {
      await prefs.setDouble(PrefsKeyConstant.alertThreshold, thresholdHpa);
      await prefs.setBool(PrefsKeyConstant.onboardingCompleted, true);
      AppAnalytics.logOnboardingCompleted(thresholdHpa: thresholdHpa);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.onboarding,
        'Complete onboarding failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
