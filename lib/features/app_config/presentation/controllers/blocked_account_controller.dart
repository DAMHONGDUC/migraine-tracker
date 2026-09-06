import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../../auth/providers.dart';
import '../../../settings/providers.dart';

/// The two things a locked-out account can still do. The gate widget calls these and shows a snackbar when one comes back false.
class BlockedAccountController {
  const BlockedAccountController(this._ref);

  final Ref _ref;

  /// Signs out, which is what clears the block: the row is keyed on the address, so an anonymous session matches nothing and the app is usable again. Local data is untouched — it never left the device.
  Future<bool> signOut() async {
    SdLogger.action(LogTagConstant.appConfig, 'Blocked account: sign out');
    try {
      await _ref.read(authRepositoryProvider).signOut();

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.appConfig,
        'Blocked account sign out failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  /// The only way out that is not sign-out: the owner blocked the address, so the owner is who can unblock it.
  Future<bool> emailSupport({required String subject}) async {
    SdLogger.action(LogTagConstant.appConfig, 'Blocked account: email support');
    try {
      return await _ref
          .read(mailLauncherProvider)
          .open(to: AppEnv.supportEmail, subject: subject);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.appConfig,
        'Blocked account support email failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}

final blockedAccountControllerProvider = Provider<BlockedAccountController>(
  BlockedAccountController.new,
);
