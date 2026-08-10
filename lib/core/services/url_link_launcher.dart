import 'package:url_launcher/url_launcher.dart';

import 'link_launcher.dart';

class UrlLinkLauncher implements LinkLauncher {
  const UrlLinkLauncher();

  /// [LaunchMode.externalApplication] so the link opens in the browser rather
  /// than a webview over the paywall — a reviewer checking the Terms link
  /// should land somewhere that obviously is Apple's own page.
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
