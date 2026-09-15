import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import 'dashboard_explore_card.dart';

/// Feature banners that surface capabilities living on other tabs — reminders, insights, data export and About — each tapping straight through.
class DashboardExploreSection extends ConsumerWidget {
  const DashboardExploreSection({super.key});

  /// The cell's height, stated outright rather than derived from a ratio.
  static double get cellHeight =>
      SdSpacingConstant.h12 * 2 +
      DashboardExploreCard.headerHeight +
      SdSpacingConstant.h8 +
      SdSpacingConstant.h24 +
      SdSpacingConstant.h4 +
      SdSpacingConstant.h16 * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: SdSpacingConstant.w4),
          child: Text(
            l10n.dashboardExplore.toUpperCase(),
            style: AppTextStyle.labelSmall.secondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisExtent: cellHeight,
          mainAxisSpacing: SdContentPaddingV2.listItemGap,
          crossAxisSpacing: SdContentPaddingV2.listItemGap,
          // Explicit padding prevents ScrollView from adding the safe area twice.
          padding: EdgeInsets.zero,
          // The dashboard's own list owns the scrolling.
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            DashboardExploreCard(
              icon: AppIconConstant.reminderActive,
              title: l10n.dashboardReminderTitle,
              content: DashboardExploreSubtitle(l10n.dashboardReminderBody),
              onTap: () => context.goNamed(AppRoutes.medications.name),
            ),
            DashboardExploreCard(
              // Distinct from the bottom nav's insights_outlined so byIcon finders stay unambiguous.
              icon: AppIconConstant.analysis,
              title: l10n.dashboardInsightsBannerTitle,
              content: DashboardExploreSubtitle(
                l10n.dashboardInsightsBannerBody,
              ),
              onTap: () => context.goNamed(AppRoutes.insights.name),
            ),
            DashboardExploreCard(
              icon: AppIconConstant.export,
              title: l10n.dashboardExportTitle,
              content: DashboardExploreSubtitle(l10n.dashboardExportBody),
              // Label export as Premium before its paywall opens.
              trailing: ref.watch(hasPremiumProvider)
                  ? null
                  : const PremiumBadge(),
              // Straight to Export — landing on Settings and hunting isn't what the card promised.
              onTap: () => NavigationUtils.toExport(context, ref),
            ),
            DashboardExploreCard(
              icon: AppIconConstant.info,
              title: l10n.dashboardAboutTitle,
              content: DashboardExploreSubtitle(l10n.dashboardAboutBody),
              // Same screen the Settings row opens.
              onTap: () => context.pushNamed(AppRoutes.about.name),
            ),
          ],
        ),
      ],
    );
  }
}
