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
import '../widgets/alert_threshold_sheet.dart';
import '../widgets/record_limit_dialog.dart';
import 'app_router.dart';

/// Navigation moves with a rule attached — an order of screens, or a condition on where the user lands. A plain push stays at its call site.
final class NavigationUtils {
  /// False means no account: backed out, or the attempt failed.
  static Future<bool> toLogin(BuildContext context) async {
    final bool? signedIn = await context.pushNamed<bool>(AppRoutes.login.name);

    return signedIn ?? false;
  }

  /// The 3-tap log flow, with the two things that must happen before it.
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

  /// The export screen, which is premium in full — the data exports and the doctor report alike.
  static Future<void> toExport(BuildContext context, WidgetRef ref) async {
    if (!ref.read(hasPremiumProvider)) {
      await toPaywall(context, ref);

      return;
    }

    await context.pushNamed<void>(AppRoutes.export.name);
  }

  /// Insights, showing [tab].
  static void toInsights(
    BuildContext context,
    WidgetRef ref,
    InsightsTab tab,
  ) {
    ref.read(insightsTabProvider.notifier).set(tab);
    context.goNamed(AppRoutes.insights.name);
  }

  /// Insights, with the pressure card showing.
  static void toPressure(BuildContext context, WidgetRef ref) =>
      toInsights(context, ref, InsightsTab.pressure);

  /// A door that means *alerts*: the pressure tab, with the threshold sheet
  /// already open on top of it (owner's call).
  ///
  /// It used to land on the tab and light the alert row up, which asked the
  /// user to find a highlight and then tap it — two steps to reach the thing
  /// the door was named after. The sheet over the tab is the same destination
  /// with neither step.
  ///
  /// **Only with premium**, and the check lives here rather than at each door:
  /// without it the card renders a pitch and no controls, so a sheet over it
  /// would be editing something the user cannot have.
  static Future<void> toPressureAlert(
    BuildContext context,
    WidgetRef ref,
  ) async {
    toPressure(context, ref);

    if (!ref.read(hasPremiumProvider) || !context.mounted) return;

    await AlertThresholdEditor.open(context, ref);
  }

  /// One notification in full. Both the list's rows and a tapped OS notification land here, so the route's path parameter is named once.
  static Future<void> toNotification(
    BuildContext context,
    String notificationId,
  ) => context.pushNamed<void>(
    AppRoutes.notification.name,
    pathParameters: <String, String>{
      AppRoutes.notificationIdParam: notificationId,
    },
  );

  /// A record limit was reached: name it, and open the paywall only if the user asks for it.
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

  /// Every locked surface goes here, signed in or not — one door, so the paywall is what a gate opens and nothing else.
  static Future<void> toPaywall(BuildContext context, WidgetRef ref) async {
    // Demand signal: how often a locked surface is tapped, and whether the user already had an account.
    AppAnalytics.logPremiumGateTapped(signedIn: ref.read(isSignedInProvider));
    await context.pushNamed<void>(AppRoutes.paywall.name);
  }
}
