import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';
import 'app_router.dart';

/// Navigation moves with a rule attached — an order of screens, or a
/// condition on where the user lands. A plain push stays at its call site.
abstract final class NavigationUtils {
  /// False means no account: backed out, or the attempt failed.
  static Future<bool> toLogin(BuildContext context) async {
    final bool? signedIn = await context.pushNamed<bool>(AppRoutes.login.name);

    return signedIn ?? false;
  }

  static Future<void> toPaywall(BuildContext context) =>
      context.pushNamed<void>(AppRoutes.paywall.name);

  /// Locked surface → paywall, signing in first if needed: a subscription
  /// needs an account to belong to. Backing out of login stops the flow.
  static Future<void> unlockPremium(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isSignedInProvider)) {
      final bool signedIn = await toLogin(context);

      if (!signedIn || !context.mounted) return;
    }

    await toPaywall(context);
  }
}
