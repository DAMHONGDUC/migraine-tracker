import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import 'dashboard_banner.dart';

/// Feature banners that surface capabilities living on other tabs — medication
/// reminders, the insights analysis, and data export — each tapping straight
/// through to the relevant tab.
class DashboardExploreSection extends StatelessWidget {
  const DashboardExploreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: AppSpacingConstant.w4),
          child: Text(
            l10n.dashboardExplore,
            style: AppTextStyle.titleSmall.secondary,
          ),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        DashboardBanner(
          icon: Icons.notifications_active_outlined,
          color: AppColors.secondary,
          title: l10n.dashboardReminderTitle,
          subtitle: l10n.dashboardReminderBody,
          onTap: () => context.goNamed(AppRoutes.medications.name),
        ),
        DashboardBanner(
          // Distinct from the bottom nav's insights_outlined so byIcon finders
          // stay unambiguous (see the byicon gotcha).
          icon: Icons.analytics_outlined,
          color: AppColors.primary,
          title: l10n.dashboardInsightsBannerTitle,
          subtitle: l10n.dashboardInsightsBannerBody,
          onTap: () => context.goNamed(AppRoutes.insights.name),
        ),
        DashboardBanner(
          icon: Icons.ios_share_outlined,
          color: AppColors.secondary,
          title: l10n.dashboardExportTitle,
          subtitle: l10n.dashboardExportBody,
          onTap: () => context.goNamed(AppRoutes.settings.name),
        ),
      ],
    );
  }
}
