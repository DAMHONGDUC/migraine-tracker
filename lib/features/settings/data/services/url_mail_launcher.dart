import 'package:url_launcher/url_launcher.dart';

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
    } catch (_) {
      return false;
    }
  }
}
