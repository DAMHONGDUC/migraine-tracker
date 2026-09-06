import 'package:system_design/common.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/constants/log_tag_constant.dart';

/// What the splash is waiting for: a caller for the callables behind the
/// dashboard.
///
/// The device check is not here — it wipes a Firestore cache, which only works
/// before anything has read one, and `ForceUpdateWrapper` reads on the first
/// frame of this very route. It runs in `main`, ahead of `runApp`
/// (`AppFreshInstall`).
class SplashController {
  const SplashController();

  /// Never throws — the splash leaves either way, because an app that cannot
  /// get past its own loading screen is worse than one that starts signed out.
  ///
  /// The bootstrap step already tried this; the retry is for the launch that
  /// had no network for it, where a second attempt costs one call.
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
