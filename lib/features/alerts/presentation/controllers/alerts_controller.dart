import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
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
