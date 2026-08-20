import 'package:system_design/common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/log_tag_constant.dart';
import 'link_launcher.dart';

class UrlLinkLauncher implements LinkLauncher {
  const UrlLinkLauncher();

  /// [LaunchMode.externalApplication] so the link opens in the browser rather
  /// than a webview over the paywall — a reviewer checking the Terms link
  /// should land somewhere that obviously is Apple's own page.
  @override
  Future<bool> open(String url) async {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      SdLogger.warning(
        LogTagConstant.link,
        'Link not opened, unparseable url',
        url,
      );

      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      // A false reaches the caller and says nothing about which link died.
      SdLogger.error(
        LogTagConstant.link,
        'Link launch failed: $url',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
