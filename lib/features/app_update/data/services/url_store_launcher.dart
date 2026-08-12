import 'package:url_launcher/url_launcher.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/services/store_launcher.dart';

class UrlStoreLauncher implements StoreLauncher {
  const UrlStoreLauncher();

  /// [LaunchMode.externalApplication] so an `https://apps.apple.com/...`
  /// link hands off to the store app instead of an in-app webview.
  @override
  Future<bool> open(String url) async {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      AppLogger.warning('Store link not opened, unparseable url', url);

      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      // The force-update screen's only button — a silent false leaves the
      // user stuck on it with nothing said anywhere.
      AppLogger.error(
        'Store launch failed: $url',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
