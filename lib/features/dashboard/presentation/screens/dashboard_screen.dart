import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../widgets/dashboard_log_button.dart';
import '../widgets/dashboard_premium_card.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/week_summary_card.dart';

/// The app's home tab (replaces the old Log tab). A calm, scrollable
/// overview: a big log call-to-action up top, this-week stats, shortcuts to
/// the other tabs, and a premium nudge for free users. Logging itself now
/// lives on a pushed route opened from [DashboardLogButton] — the 3-tap flow
/// is unchanged, just launched from here.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacingConstant.w24,
          AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
          AppSpacingConstant.w24,
          AppScaffold.bottomNavInset(context) + AppSpacingConstant.h24,
        ),
        children: [
          const DashboardLogButton(),
          SizedBox(height: AppSpacingConstant.h24),
          const WeekSummaryCard(),
          SizedBox(height: AppSpacingConstant.h24),
          const QuickAccessSection(),
          SizedBox(height: AppSpacingConstant.h24),
          const DashboardPremiumCard(),
        ],
      ),
    );
  }
}
