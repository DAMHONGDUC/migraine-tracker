import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/sleep_summary.dart';
import '../../../health/domain/entities/step_summary.dart';
import '../../../health/providers.dart';
import '../../../premium/providers.dart';
import 'dashboard_explore_card.dart';

/// Last night's sleep, in the dashboard's explore grid.
///
/// Premium as a whole, like the Settings row that leads to the same screen:
/// the insight behind it is premium, so connecting first would be a permission
/// prompt for nothing. A free user gets a zero and the unlock button — and the
/// real figure is never read, so it is not in their widget tree to leak (the
/// same rule `PremiumGate` keeps).
class DashboardSleepCard extends ConsumerWidget {
  const DashboardSleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);
    final bool connected = premium && ref.watch(healthControllerProvider).sleep;
    final SleepSummary? summary = connected
        ? ref.watch(sleepSummaryProvider).value
        : null;
    final Duration slept = summary?.latest?.duration ?? Duration.zero;
    final VoidCallback onTap = premium
        ? () => context.pushNamed(AppRoutes.sleep.name)
        : () => NavigationUtils.toPaywall(context, ref);

    return DashboardExploreCard(
      icon: Icons.bedtime_outlined,
      title: l10n.dashboardSleepTitle,
      onTap: onTap,
      content: DashboardExploreReading(
        value: slept.label(l10n),
        actionLabel: switch ((premium, connected)) {
          (false, _) => l10n.premiumUnlock,
          (true, false) => l10n.dashboardHealthConnect,
          (true, true) => null,
        },
        onAction: onTap,
      ),
    );
  }
}

/// Today's step count, in the same grid.
///
/// Not premium, unlike [DashboardSleepCard]: what Apple Health counted is free
/// wherever it appears — it is the answer to "did connecting work". Only the
/// step *correlation*, over on `/activity`, is premium.
class DashboardStepsCard extends ConsumerWidget {
  const DashboardStepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool connected = ref.watch(healthControllerProvider).steps;
    final StepSummary? summary = connected
        ? ref.watch(stepSummaryProvider).value
        : null;
    // The connect button navigates, it never prompts: the Apple Health sheet
    // is only ever raised on the detail screen that owns the switch.
    void onTap() => context.pushNamed(AppRoutes.activity.name);

    return DashboardExploreCard(
      icon: Icons.directions_walk,
      title: l10n.dashboardStepsTitle,
      onTap: onTap,
      content: DashboardExploreReading(
        value: (summary?.latest?.count ?? 0).label(l10n),
        actionLabel: connected ? null : l10n.dashboardHealthConnect,
        onAction: onTap,
      ),
    );
  }
}
