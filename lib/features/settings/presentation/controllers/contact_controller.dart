import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../providers.dart';

/// Opens the mail app addressed to support. The contact screen only calls
/// [emailSupport] and shows a snackbar when it comes back false.
class ContactController {
  const ContactController(this._ref);

  final Ref _ref;

  Future<bool> emailSupport({required String subject, String? body}) async {
    SdLogger.action(LogTagConstant.contact, 'Contact support: email');
    try {
      return await _ref
          .read(mailLauncherProvider)
          .open(to: AppEnv.supportEmail, subject: subject, body: body);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.contact,
        'Contact support email failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
