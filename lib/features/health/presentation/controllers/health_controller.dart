import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/health_connections.dart';
import '../../domain/enums/health_data_kind.dart';
import '../../providers.dart';

/// Owns which Apple Health sources are connected, one flag per source.
class HealthController extends Notifier<HealthConnections> {
  /// The single flag both sources shared before they could be connected separately. Read once, to carry an existing user across.

  static String keyOf(HealthDataKind kind) => switch (kind) {
    HealthDataKind.sleep => PrefsKeyConstant.healthSleep,
    HealthDataKind.steps => PrefsKeyConstant.healthSteps,
    HealthDataKind.cycle => PrefsKeyConstant.healthCycle,
  };

  @override
  HealthConnections build() {
    final SecureStore prefs = ref.watch(secureStoreProvider);
    // Someone who connected under the old single switch had both; splitting the flag must not read as the app quietly disconnecting on them.
    final bool legacy =
        prefs.getBool(PrefsKeyConstant.healthConnected) ?? false;

    return HealthConnections(
      sleep: prefs.getBool(PrefsKeyConstant.healthSleep) ?? legacy,
      steps: prefs.getBool(PrefsKeyConstant.healthSteps) ?? legacy,
      // No legacy fallback: the old single switch never asked about reproductive health, so it cannot answer for it.
      cycle: prefs.getBool(PrefsKeyConstant.healthCycle) ?? false,
    );
  }

  /// Returns false when the platform refused outright (no HealthKit on this device, or the sheet failed) — the caller surfaces that.
  Future<bool> connect(HealthDataKind kind) async {
    SdLogger.action(
      LogTagConstant.health,
      'Connect Apple Health ${kind.name}',
      true,
    );
    try {
      final bool answered = await ref
          .read(healthRepositoryProvider)
          .requestAuthorization(kind);

      if (!answered) return false;

      await ref.read(secureStoreProvider).setBool(keyOf(kind), true);
      AppAnalytics.logHealthConnectionToggled(enabled: true);
      state = state.withKind(kind, true);

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.health,
        'Connect Apple Health ${kind.name} failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Stops the app reading this source.
  Future<void> disconnect(HealthDataKind kind) async {
    SdLogger.action(
      LogTagConstant.health,
      'Connect Apple Health ${kind.name}',
      false,
    );
    try {
      await ref.read(secureStoreProvider).setBool(keyOf(kind), false);
      AppAnalytics.logHealthConnectionToggled(enabled: false);
      state = state.withKind(kind, false);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.health,
        'Disconnect Apple Health ${kind.name} failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> setConnected(HealthDataKind kind, bool connected) async {
    if (connected) return connect(kind);

    await disconnect(kind);

    return true;
  }

  /// Every source at once, for the GDPR wipe — it clears the legacy flag too, so a wipe cannot leave the old key behind to reconnect on next launch.
  Future<void> disconnectAll() async {
    final SecureStore prefs = ref.read(secureStoreProvider);

    await prefs.setBool(PrefsKeyConstant.healthConnected, false);
    for (final HealthDataKind kind in HealthDataKind.values) {
      await disconnect(kind);
    }
  }
}
