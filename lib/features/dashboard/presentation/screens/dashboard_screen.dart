import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../attacks/providers.dart';
import '../../../medications/providers.dart';
import '../../../premium/providers.dart';
import '../widgets/dashboard_explore_section.dart';
import '../widgets/dashboard_log_button.dart';
import '../widgets/dashboard_premium_card.dart';
import '../widgets/next_reminder_banner.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/week_summary_card.dart';

/// The app's home tab (replaces the old Log tab). A calm, scrollable overview,
/// top to bottom: premium nudge (free users), the log call-to-action, the next
/// medication reminder (when one is scheduled), this-week stats, quick-access
/// shortcuts, and the feature banners. Logging itself opens as a pushed route
/// from [DashboardLogButton] — the 3-tap flow is unchanged.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showPremium = !ref.watch(hasPremiumProvider);
    final nextReminder = ref.watch(nextReminderProvider);

    // Only the sections that should show, in order — gaps are inserted between
    // them below so a hidden section never leaves a double gap.
    final sections = <Widget>[
      const DashboardLogButton(),
      const WeekSummaryCard(),
      if (nextReminder != null) NextReminderBanner(reminder: nextReminder),
      const QuickAccessSection(),
      const DashboardExploreSection(),
      if (showPremium) const DashboardPremiumCard(),
    ];

    return AppScaffold(
      title: Text(l10n.dashboardGreeting),
      // No auth yet: signing in / account management lives under Settings.
      // When auth lands, swap this for the signed-in user's name + avatar.
      actions: [
        AppButton.secondary(
          compact: true,
          icon: Icons.person_outline,
          label: l10n.dashboardSignIn,
          onPressed: () => context.goNamed(AppRoutes.settings.name),
        ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      body: AppRefreshIndicator(
        onRefresh: () => pullRefresh(() {
          ref
            ..invalidate(attacksStreamProvider)
            ..invalidate(medicationRemindersStreamProvider)
            ..invalidate(isPremiumProvider)
            ..invalidate(clockProvider);
        }),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w24,
            AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
            AppSpacingConstant.w24,
            AppScaffold.bottomNavInset(context) + AppSpacingConstant.h24,
          ),
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) SizedBox(height: AppSpacingConstant.h24),
              sections[i],
            ],
          ],
        ),
      ),
    );
  }
}
