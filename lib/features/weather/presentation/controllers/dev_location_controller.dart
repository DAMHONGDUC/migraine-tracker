import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/enums/dev_location.dart';

/// Holds the dev-only faked position, and is the only thing that writes it.
///
/// **A prod flavour reads [DevLocation.off] whatever is stored.** The gate is
/// here rather than only on the Settings row, so a preference left behind by
/// a dev build installed over the same bundle id cannot follow the user into
/// a release one.
class DevLocationController extends Notifier<DevLocation> {
  @override
  DevLocation build() {
    if (AppEnv.isProd) return DevLocation.off;

    return DevLocation.fromName(
      ref
          .watch(sharedPreferencesProvider)
          .getString(PrefsKeyConstant.devFakeLocation),
    );
  }

  Future<void> set(DevLocation location) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);

    AppLogger.action('Dev fake location', location.name);
    try {
      await prefs.setString(PrefsKeyConstant.devFakeLocation, location.name);
      state = location;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Dev fake location failed',
        error: error,
        stackTrace: stackTrace,
        data: location.name,
      );
      rethrow;
    }
  }
}
