import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/attacks/providers.dart';
import '../../features/auth/providers.dart';
import '../../features/insights/domain/enums/insights_tab.dart';
import '../../features/insights/providers.dart';
import '../../features/premium/providers.dart';
import '../analytics/app_analytics.dart';
import '../constants/premium_limit_constant.dart';
import '../extensions/context_extensions.dart';
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

  /// The 3-tap log flow, with the two things that must happen before it.
  ///
  /// The free plan's attack limit is the one gate that lands here, and it
  /// names itself first like every other record limit. The flow state is then
  /// reset so the screen always starts fresh at intensity.
  ///
  /// Two ways in — the dashboard's button and the home-screen widget — and
  /// the rule is why this lives here: a second entry point that forgot the
  /// gate would be a free user walking past the wall.
  static Future<void> toLog(BuildContext context, WidgetRef ref) async {
    if (!ref.read(canLogAttackProvider)) {
      await toPaywallFromLimit(
        context,
        ref,
        title: context.l10n.attackLimitTitle(PremiumLimitConstant.attacks),
        body: context.l10n.attackLimitBody(PremiumLimitConstant.attacks),
      );
      return;
    }

    ref.read(logControllerProvider.notifier).reset();
    if (context.mounted) await context.pushNamed<void>(AppRoutes.log.name);
  }

  /// The export screen, which is premium in full — the data exports and the
  /// doctor report alike.
  ///
  /// The rule is why this lives here: two doors lead to it, the dashboard's
  /// explore card and the Settings row, and a second one that forgot the gate
  /// would hand a free user everything the paywall sells. Straight to the
  /// paywall with no [RecordLimitDialog] — both doors already wear the badge,
  /// so a dialog would repeat what the surface just said.
  static Future<void> toExport(BuildContext context, WidgetRef ref) async {
    if (!ref.read(hasPremiumProvider)) {
      await toPaywall(context, ref);

      return;
    }

    await context.pushNamed<void>(AppRoutes.export.name);
  }

  /// Insights, showing [tab].
  ///
  /// The tab is a branch selection plus a provider write, so every shortcut
  /// into a card goes through here rather than each remembering both halves.
  static void toInsights(
    BuildContext context,
    WidgetRef ref,
    InsightsTab tab,
  ) {
    ref.read(insightsTabProvider.notifier).set(tab);
    context.goNamed(AppRoutes.insights.name);
  }

  /// Insights, with the pressure card showing.
  ///
  /// The rule is why this lives here: `/pressure` is gone — the alert is set
  /// on the card now — so "take me to pressure" is a tab selection plus a
  /// branch switch, and three call sites would otherwise each half-remember
  /// it.
  ///
  /// [highlightAlert] is for the doors that mean *alerts* rather than
  /// pressure in general — the dashboard tile, the Settings row, the alert
  /// notification. The switch is the last thing on a tall card, so landing on
  /// the card without pointing at it leaves the user hunting.
  ///
  /// **Only with premium**, and that check belongs here rather than at each
  /// call site: without it the card renders one pitch and no controls, so
  /// there would be no row to scroll to and the request would sit unconsumed
  /// until it fired at some unrelated later visit.
  static void toPressure(
    BuildContext context,
    WidgetRef ref, {
    bool highlightAlert = false,
  }) {
    if (highlightAlert && ref.read(hasPremiumProvider)) {
      ref.read(pressureAlertHighlightProvider.notifier).request();
    }
    toInsights(context, ref, InsightsTab.pressure);
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
