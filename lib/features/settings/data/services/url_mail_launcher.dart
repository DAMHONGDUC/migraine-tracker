import 'package:system_design/common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/services/mail_launcher.dart';

class UrlMailLauncher implements MailLauncher {
  const UrlMailLauncher();

  @override
  Future<bool> open({
    required String to,
    required String subject,
    String? body,
  }) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: <String, String>{'subject': subject, 'body': ?body},
    );

    try {
      return await launchUrl(uri);
    } catch (error, stackTrace) {
      // No mail client is the usual cause, and a bare false never says so.
      SdLogger.error(
        LogTagConstant.contact,
        'Mail launch failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
