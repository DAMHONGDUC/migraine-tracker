import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

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
          padding: EdgeInsets.only(left: SdSpacingConstant.w4),
          child: Text(
            l10n.dashboardExplore,
            style: AppTextStyle.titleSmall.secondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Column(
          spacing: SdSpacingConstant.h12,
          children: [
            SdBannerV2(
              icon: Icons.notifications_active_outlined,
              color: AppColors.secondary,
              title: l10n.dashboardReminderTitle,
              subtitle: l10n.dashboardReminderBody,
              onTap: () => context.goNamed(AppRoutes.medications.name),
            ),
            SdBannerV2(
              // Distinct from the bottom nav's insights_outlined so byIcon finders stay unambiguous.
              icon: Icons.analytics_outlined,
              color: AppColors.primary,
              title: l10n.dashboardInsightsBannerTitle,
              subtitle: l10n.dashboardInsightsBannerBody,
              onTap: () => context.goNamed(AppRoutes.insights.name),
            ),
            SdBannerV2(
              icon: Icons.ios_share_outlined,
              color: AppColors.secondary,
              title: l10n.dashboardExportTitle,
              subtitle: l10n.dashboardExportBody,
              // Straight to Export — landing on Settings and hunting isn't what the banner promised.
              onTap: () => context.pushNamed(AppRoutes.export.name),
            ),
          ],
        ),
      ],
    );
  }
}
