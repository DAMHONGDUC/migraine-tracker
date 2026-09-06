import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/storage/prefs_install_store.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../auth/providers.dart';

/// What the splash is waiting for: the first-launch guard, and a caller for the callables after it.
class SplashController {
  const SplashController(this._ref);

  final Ref _ref;

  /// Never throws — the splash leaves either way, because an app that cannot get past its own loading screen is worse than one that starts signed in.
  Future<void> run() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await SdReinstallGuard.run(
        logTag: LogTagConstant.storage,
        installScoped: PrefsInstallStore(prefs),
        deviceScoped: _ref.read(secureStoreProvider),
        signOut: _ref.read(authRepositoryProvider).signOut,
      );
      // After the guard, always: a reinstall purge signs the old session out and leaves no caller at all, and `getWeather` will not serve one it cannot name.
      await AppBootstrap.ensureAnonymousSession();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.storage,
        'Splash startup work failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
