import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/attacks/providers.dart';
import '../../features/auth/providers.dart';
import '../../features/insights/domain/enums/insights_tab.dart';
import '../../features/insights/providers.dart';
import '../../features/premium/providers.dart';
import '../analytics/app_analytics.dart';
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

  /// The 3-tap log flow, with the one thing that must happen before it.
  ///
  /// There is no gate here any more: logging an attack is never refused
  /// (`docs/PREMIUM_RULES.md`), and what the free plan limits is how far back
  /// the record can be READ. The reset stays — a flow reopened on the last
  /// attack's answers would record them again.
  static Future<void> toLog(BuildContext context, WidgetRef ref) async {
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
  static void toInsights(BuildContext context, WidgetRef ref, InsightsTab tab) {
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

    // The server never pushes to an anonymous session, so registration throws
    // `accountRequired` — and a paying user meeting that error after flipping
    // the switch reads as a broken feature. Sign-in comes first instead.
    if (!ref.read(isSignedInProvider)) {
      final bool signedIn = await toLogin(context);

      if (!signedIn || !context.mounted) return;
    }

    await AlertThresholdEditor.open(context, ref);
  }

  /// Resolves once the launch has left the splash.
  ///
  /// **Every deep link waits on this before it navigates** (see the two tap
  /// listeners). The splash ends by *replacing* the stack with the dashboard,
  /// and a link that pushed its screen while those dots were still up got
  /// wiped a second later — the user watched their notification open and then
  /// the dashboard take its place. Waiting also puts the dashboard underneath,
  /// so backing out of the pushed screen lands where it would from anywhere
  /// else instead of on a spent splash.
  ///
  /// It asks the ROUTER, not a flag the splash sets: a launch that skips the
  /// splash — `pumpApp` overrides `initialLocationProvider`, and any future
  /// route could — is already past it, and a signal nobody sends would hold
  /// every deep link forever.
  static Future<void> whenPastSplash(GoRouter router) {
    bool past() => router.state.matchedLocation != AppRoutes.splash.path;

    if (past()) return Future<void>.value();

    final Completer<void> arrived = Completer<void>();
    late final VoidCallback listener;

    listener = () {
      if (arrived.isCompleted || !past()) return;

      router.routerDelegate.removeListener(listener);
      arrived.complete();
    };
    router.routerDelegate.addListener(listener);

    return arrived.future;
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
