import 'package:system_design/common.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/log_tag_constant.dart';

/// What the splash route is waiting for: a caller for the callables behind the
/// dashboard.
///
/// **After the device check, and that is why it is here rather than in a
/// bootstrap step.** The wipe signs the old session out, so a session opened
/// ahead of it would be the one it deleted; this route only mounts once
/// `FreshInstallGate` has let the app build.
class SplashController {
  const SplashController();

  /// Never throws — the splash leaves either way, because an app that cannot
  /// get past its own loading screen is worse than one that starts signed out.
  ///
  /// The next feature needing a uid asks again.
  Future<void> run() async {
    try {
      await AppBootstrap.ensureAnonymousSession();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.bootstrap,
        'Splash startup work failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
