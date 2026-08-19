import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../weather/providers.dart';

/// Orchestrates onboarding: the location permission request and persisting
/// the user's choices. The screen only renders pages and calls these.
class OnboardingController {
  const OnboardingController(this._ref);

  final Ref _ref;

  /// Raises the While-Using prompt (reduced accuracy).
  ///
  /// **This is where the ask is EXPLAINED, and it is one of two places that
  /// raise it.** It used to ask by requesting a position, which meant every
  /// weather read could prompt — launch, resume, logging an attack. Here the
  /// ask sits next to the screen saying why it is wanted. Best-effort: denial
  /// is fine, weather is simply skipped, and the dashboard's weather card
  /// offers the ask again on the surface it feeds (`_LocationPrompt`) — a
  /// "Not now" here used to be final.
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

  /// Forgets that onboarding was ever done, so the router redirects here
  /// again on the next frame. Dev tooling only — the keys stay private to
  /// this feature, and Settings reaches this through `providers.dart` rather
  /// than importing the controller.
  ///
  /// It clears no user data: the caller decides whether a reset means "show
  /// the pages again" or "make this look like a fresh install".
  Future<void> reset() async {
    final prefs = _ref.read(sharedPreferencesProvider);

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
  ///
  /// **Last, and separate from location.** Two OS dialogs stacked on one
  /// screen get dismissed as a pair, and the second one is never read. This
  /// one comes after the pages are done, when the user has seen what the
  /// reminders and alerts are for.
  ///
  /// No settings sheet on refusal — [AppPermission.ensure] needs a context
  /// and there is nothing to recover here: a user who says no still gets the
  /// whole app, and the features that need it ask again where they live.
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

  /// Persists the personal pressure threshold (hard rule 7: user-tunable)
  /// and marks onboarding as done so the router stops redirecting here.
  Future<void> complete({required double thresholdHpa}) async {
    final prefs = _ref.read(sharedPreferencesProvider);

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
