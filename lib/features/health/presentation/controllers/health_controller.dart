import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../providers.dart';

/// Owns whether Apple Health is connected.
///
/// "Connected" is the user's own choice, kept in prefs — it is not a mirror
/// of the OS grant, because there is nothing to mirror: iOS never reports
/// whether a *read* permission was allowed. All the app can observe is that
/// the sheet was answered, so the switch records intent and the reads speak
/// for themselves (empty = nothing to show).
class HealthController extends Notifier<bool> {
  static const String connectedKey = 'health_connected';

  @override
  bool build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);

    return prefs.getBool(connectedKey) ?? false;
  }

  /// Returns false when the platform refused outright (no HealthKit on this
  /// device, or the sheet failed) — the caller surfaces that. A granted-
  /// looking true still guarantees nothing about what was ticked.
  Future<bool> connect() async {
    AppLogger.action('Connect Apple Health', true);
    try {
      final bool answered = await ref
          .read(healthRepositoryProvider)
          .requestAuthorization();

      if (!answered) return false;

      await ref.read(sharedPreferencesProvider).setBool(connectedKey, true);
      AppAnalytics.logHealthConnectionToggled(enabled: true);
      state = true;

      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Connect Apple Health failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Stops the app reading sleep. It cannot revoke the OS grant — only
  /// Settings → Privacy & Security → Health can — so this is the app's own
  /// switch, and the UI says so rather than implying a revoke.
  Future<void> disconnect() async {
    AppLogger.action('Connect Apple Health', false);
    try {
      await ref.read(sharedPreferencesProvider).setBool(connectedKey, false);
      AppAnalytics.logHealthConnectionToggled(enabled: false);
      state = false;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Disconnect Apple Health failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> setConnected(bool connected) async {
    if (connected) return connect();

    await disconnect();

    return true;
  }
}
