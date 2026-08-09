import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';
import '../analytics/app_analytics.dart';
import '../widgets/record_limit_dialog.dart';
import 'app_router.dart';

/// Navigation moves with a rule attached — an order of screens, or a
/// condition on where the user lands. A plain push stays at its call site.
final class NavigationUtils {
  /// False means no account: backed out, or the attempt failed.
  static Future<bool> toLogin(BuildContext context) async {
    final bool? signedIn = await context.pushNamed<bool>(AppRoutes.login.name);

    return signedIn ?? false;
  }

  /// One notification in full. Both the list's rows and a tapped OS
  /// notification land here, so the route's path parameter is named once.
  static Future<void> toNotification(
    BuildContext context,
    String notificationId,
  ) => context.pushNamed<void>(
    AppRoutes.notification.name,
    pathParameters: <String, String>{
      AppRoutes.notificationIdParam: notificationId,
    },
  );

  /// Every locked surface goes here, signed in or not — one door, so the
  /// paywall is what a gate opens and nothing else.
  ///
  /// The account question is the paywall's, not this method's: signed out
  /// it offers "Sign in to continue" (which comes back here through
  /// [toLogin]) and signed in it offers the purchase. That way the pitch is
  /// always what the user sees first, and a login screen never appears in
  /// front of a paywall they haven't been shown yet.
  /// A record limit was reached: name it, and open the paywall only if the
  /// user asks for it.
  ///
  /// The order is the rule, and it is why this lives here rather than at
  /// three call sites — see [RecordLimitDialog] for why a limit is always
  /// named before the pitch.
  static Future<void> toPaywallFromLimit(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String body,
  }) async {
    final bool? unlock = await RecordLimitDialog(
      title: title,
      body: body,
    ).show(context);

    if (unlock != true || !context.mounted) return;

    await toPaywall(context, ref);
  }

  static Future<void> toPaywall(BuildContext context, WidgetRef ref) async {
    // Demand signal: how often a locked surface is tapped, and whether the user already had an account.
    AppAnalytics.logPremiumGateTapped(signedIn: ref.read(isSignedInProvider));
    await context.pushNamed<void>(AppRoutes.paywall.name);
  }
}
