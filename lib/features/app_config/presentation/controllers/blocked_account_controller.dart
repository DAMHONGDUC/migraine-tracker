import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../../auth/providers.dart';
import '../../../settings/providers.dart';

/// How a sign-out from the block screen ended.
enum BlockedSignOut {
  /// Signed out, the device emptied — the app comes back as a fresh anonymous session.
  done,

  /// Changes are still owed to the server, so nothing was removed and the account stays signed in.
  owed,

  /// Something else failed; logged where it happened.
  failed,
}

/// The two things a locked-out account can still do. The gate widget calls these and shows a snackbar when one comes back false.
class BlockedAccountController {
  const BlockedAccountController(this._ref);

  final Ref _ref;

  /// Signs out, which is what clears the block: the row is keyed on the address, so an anonymous session matches nothing and the app is usable again.
  ///
  /// The normal sign-out, not a bare one: a signed-in account has been
  /// syncing, so this device's records are that account's and the next person
  /// on it must not inherit them. It pushes what is still owed, empties the
  /// device and only then signs out — and refuses, leaving everything, while a
  /// record has not reached the server (`AccountController.signOut`).
  Future<BlockedSignOut> signOut() async {
    SdLogger.action(LogTagConstant.appConfig, 'Blocked account: sign out');
    try {
      final bool signedOut = await _ref
          .read(accountControllerProvider)
          .signOut();

      return signedOut ? BlockedSignOut.done : BlockedSignOut.owed;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.appConfig,
        'Blocked account sign out failed',
        error: error,
        stackTrace: stackTrace,
      );

      return BlockedSignOut.failed;
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
