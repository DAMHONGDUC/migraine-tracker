import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/providers.dart';

/// The one path from a locked surface to the paywall.
///
/// A subscription needs an account to belong to, so a signed-out user is
/// sent to sign in first and only continues to the paywall once that
/// succeeded. Backing out of the login screen ends the flow quietly — the
/// user simply stays on the locked surface they tapped from.
///
/// Navigation only; the entitlement decision itself lives in
/// `hasPremiumProvider`.
abstract final class PremiumUnlockFlow {
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isSignedInProvider)) {
      final bool? signedIn = await context.pushNamed<bool>(
        AppRoutes.login.name,
      );

      if (signedIn != true || !context.mounted) return;
    }

    await context.pushNamed(AppRoutes.paywall.name);
  }
}
