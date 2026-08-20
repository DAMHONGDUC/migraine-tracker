import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../domain/entities/health_connections.dart';
import '../../domain/enums/health_data_kind.dart';
import '../../providers.dart';

/// Owns which Apple Health sources are connected, one flag per source.
///
/// "Connected" is the user's own choice, kept in prefs — it is not a mirror
/// of the OS grant, because there is nothing to mirror: iOS never reports
/// whether a *read* permission was allowed. All the app can observe is that
/// the sheet was answered, so the switch records intent and the reads speak
/// for themselves (empty = nothing to show).
class HealthController extends Notifier<HealthConnections> {
  /// The single flag both sources shared before they could be connected
  /// separately. Read once, to carry an existing user across.

  static String keyOf(HealthDataKind kind) => switch (kind) {
    HealthDataKind.sleep => PrefsKeyConstant.healthSleep,
    HealthDataKind.steps => PrefsKeyConstant.healthSteps,
  };

  @override
  HealthConnections build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    // Someone who connected under the old single switch had both; splitting
    // the flag must not read as the app quietly disconnecting on them.
    final bool legacy =
        prefs.getBool(PrefsKeyConstant.healthConnected) ?? false;

    return HealthConnections(
      sleep: prefs.getBool(PrefsKeyConstant.healthSleep) ?? legacy,
      steps: prefs.getBool(PrefsKeyConstant.healthSteps) ?? legacy,
    );
  }

  /// Returns false when the platform refused outright (no HealthKit on this
  /// device, or the sheet failed) — the caller surfaces that. A granted-
  /// looking true still guarantees nothing about what was ticked.
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

      await ref.read(sharedPreferencesProvider).setBool(keyOf(kind), true);
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

  /// Stops the app reading this source. It cannot revoke the OS grant — only
  /// Settings → Privacy & Security → Health can — so this is the app's own
  /// switch, and the UI says so rather than implying a revoke.
  Future<void> disconnect(HealthDataKind kind) async {
    SdLogger.action(
      LogTagConstant.health,
      'Connect Apple Health ${kind.name}',
      false,
    );
    try {
      await ref.read(sharedPreferencesProvider).setBool(keyOf(kind), false);
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

  /// Every source at once, for the GDPR wipe — it clears the legacy flag too,
  /// so a wipe cannot leave the old key behind to reconnect on next launch.
  Future<void> disconnectAll() async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);

    await prefs.setBool(PrefsKeyConstant.healthConnected, false);
    for (final HealthDataKind kind in HealthDataKind.values) {
      await disconnect(kind);
    }
  }
}
