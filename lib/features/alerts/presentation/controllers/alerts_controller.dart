import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../auth/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/alert_threshold_range.dart';
import '../../domain/entities/alerts_settings.dart';
import '../../providers.dart';

/// Owns the alerts toggle + threshold.
class AlertsController extends AsyncNotifier<AlertsSettings> {
  @override
  AlertsSettings build() {
    final prefs = ref.watch(secureStoreProvider);
    return AlertsSettings(
      enabled: prefs.getBool(PrefsKeyConstant.alertsEnabled) ?? false,
      thresholdHpa:
          prefs.getDouble(PrefsKeyConstant.alertThreshold) ??
          AlertThresholdRange.initial,
    );
  }

  /// Applies what the threshold sheet came back with.
  ///
  /// Threshold first, and that order is the point: `setEnabled(true)`
  /// registers the device with the threshold it reads off the current state,
  /// so writing the number second would register the old one and leave the
  /// server disagreeing with the slider the user just moved.
  Future<void> apply(AlertsSettings next) async {
    final AlertsSettings current = state.requireValue;

    if (next.thresholdHpa != current.thresholdHpa) {
      await setThreshold(next.thresholdHpa);
    }
    if (next.enabled != current.enabled) await setEnabled(next.enabled);
  }

  /// Switches alerts on at [AlertThresholdRange.autoEnable], once, for an
  /// account that can actually receive them.
  ///
  /// Owner's rule: a user who signed in and paid should not have to find the
  /// sheet to get the thing they paid for. Called from the app root whenever
  /// the account or the entitlement changes — sign-in of a subscriber, and the
  /// moment a purchase lands — and it does its own gating, so the two call
  /// sites stay one line each.
  ///
  /// Three things stop it, and each is a different "no":
  /// - the flag, so this happens exactly once per install and the OS
  ///   notification prompt is never raised twice by a decision the user did not
  ///   make;
  /// - no account or no premium, because the push chain refuses both
  ///   (`lib/features/alerts/CLAUDE.md`) — registering either would write a
  ///   token the cron never reads;
  /// - alerts already on, which is the user's own answer and outranks this.
  ///
  /// The flag is written after the attempt whatever it returned. A failure here
  /// is a denied permission or a device with no fix, and retrying it on every
  /// launch would be the app asking again for something it was already told no
  /// about.
  Future<void> autoEnableOnce() async {
    final SecureStore prefs = ref.read(secureStoreProvider);
    final bool asked = prefs.getBool(PrefsKeyConstant.alertsAutoEnabled) ?? false;
    final AlertsSettings current = state.requireValue;

    if (asked) return;
    if (!ref.read(isSignedInProvider) || !ref.read(hasPremiumProvider)) return;
    if (current.enabled) {
      await prefs.setBool(PrefsKeyConstant.alertsAutoEnabled, true);
      return;
    }

    SdLogger.action(
      LogTagConstant.alerts,
      'Auto-enable pressure alerts',
      <String, Object?>{'thresholdHpa': AlertThresholdRange.autoEnable},
    );
    await apply(
      current.copyWith(
        enabled: true,
        thresholdHpa: AlertThresholdRange.autoEnable,
      ),
    );
    await prefs.setBool(PrefsKeyConstant.alertsAutoEnabled, true);
    SdLogger.info(
      LogTagConstant.alerts,
      'Auto-enable pressure alerts finished',
      <String, Object?>{
        'enabled': state.value?.enabled,
        'thresholdHpa': state.value?.thresholdHpa,
      },
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.requireValue;

    SdLogger.action(LogTagConstant.alerts, 'Toggle pressure alerts', enabled);
    AppAnalytics.logAlertsToggled(enabled: enabled);
    state = await AsyncValue.guard(() async {
      final repo = ref.read(alertRegistrationRepositoryProvider);

      if (enabled) {
        await repo.register(thresholdHpa: current.thresholdHpa);
      } else {
        await repo.unregister();
      }
      await ref
          .read(secureStoreProvider)
          .setBool(PrefsKeyConstant.alertsEnabled, enabled);
      return current.copyWith(enabled: enabled);
    });
    if (state case AsyncError(:final error, :final stackTrace)) {
      SdLogger.error(
        LogTagConstant.alerts,
        'Alerts registration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setThreshold(double thresholdHpa) async {
    final current = state.requireValue;

    SdLogger.action(
      LogTagConstant.alerts,
      'Set alert threshold (hPa)',
      thresholdHpa,
    );
    AppAnalytics.logAlertThresholdSet(thresholdHpa);
    try {
      await ref
          .read(secureStoreProvider)
          .setDouble(PrefsKeyConstant.alertThreshold, thresholdHpa);
      if (current.enabled) {
        await ref
            .read(alertRegistrationRepositoryProvider)
            .updateThreshold(thresholdHpa);
      }
      state = AsyncData(current.copyWith(thresholdHpa: thresholdHpa));
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.alerts,
        'Set alert threshold failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
