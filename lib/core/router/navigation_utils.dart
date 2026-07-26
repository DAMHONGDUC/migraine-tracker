import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';
import 'app_router.dart';

/// Navigation moves that more than one screen needs, in one place.
///
/// Anything that is "push this route" belongs at its call site; what lands
/// here is a move with a *rule* attached — an order of screens, or a
/// condition deciding where the user goes. Those are the ones that rot when
/// each caller reimplements them, because a second copy is written without
/// the condition the first one had.
abstract final class NavigationUtils {
  /// Opens sign-in and resolves to whether an account exists afterwards.
  /// False covers both "backed out" and "the attempt failed".
  static Future<bool> toLogin(BuildContext context) async {
    final bool? signedIn = await context.pushNamed<bool>(AppRoutes.login.name);

    return signedIn ?? false;
  }

  static Future<void> toPaywall(BuildContext context) =>
      context.pushNamed<void>(AppRoutes.paywall.name);

  /// The one path from a locked surface to the paywall.
  ///
  /// A subscription needs an account to belong to, so a signed-out user
  /// signs in first and only continues once that succeeded. Backing out of
  /// the login screen ends the flow quietly — the user stays on the locked
  /// surface they tapped from, rather than landing on a paywall they cannot
  /// buy from.
  ///
  /// Navigation only; whether the user *is* premium stays in
  /// `hasPremiumProvider`.
  static Future<void> unlockPremium(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isSignedInProvider)) {
      final bool signedIn = await toLogin(context);

      if (!signedIn || !context.mounted) return;
    }

    await toPaywall(context);
  }
}
