import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/store_launcher.dart';

class UrlStoreLauncher implements StoreLauncher {
  const UrlStoreLauncher();

  /// [LaunchMode.externalApplication] so an `https://apps.apple.com/...`
  /// link hands off to the store app instead of an in-app webview.
  @override
  Future<bool> open(String url) async {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
