import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../health/providers.dart';
import 'dashboard_explore_card.dart';
import 'dashboard_health_card.dart';

/// Feature banners that surface capabilities living on other tabs —
/// reminders, insights, last night's sleep, today's steps and data export —
/// each tapping straight through.
///
/// **One grid, two to a row: every card is exactly the same size.**
/// Owner's rule, and it is why this is a `GridView` again. It was hand-laid
/// rows before, which equalised height *within* a row but not across them —
/// so a card carrying a reading and a button made its row half again as tall
/// as the row above, and five cards read as three unrelated pairs.
///
/// The cost is the one the row layout existed to avoid: a fixed cell cannot
/// grow for a long Vietnamese subtitle or a large accessibility text size.
/// Every cell therefore clips inside its own box rather than overflowing the
/// grid — see [DashboardExploreCard], where the content sits in an `Expanded`
/// and every string is capped with an ellipsis.
class DashboardExploreSection extends ConsumerWidget {
  const DashboardExploreSection({super.key});

  /// Slightly wider than tall. The grid derives the height from the cell
  /// width, so this one number is the whole of the "same size" rule.
  ///
  /// **What sets the floor is the health cards, not the wordier ones.** A
  /// square spent ~175pt of height on cards whose text used half of it. What
  /// cannot shrink is [DashboardExploreReading]: its figure plus a button
  /// measure 76pt, and the button is 48 of that because a tap target does not
  /// go below it. With [DashboardExploreCard]'s 80pt of chrome that puts the
  /// hard floor at 156pt, i.e. a ratio of about 1.12 at the 393pt design
  /// width — this sits below it on purpose, so a longer label or a bumped
  /// text size has somewhere to go. Measure before lowering it further; the
  /// subtitle cards will look fine long after the health ones have overflowed.
  static const double cellAspectRatio = 1.05;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Absent off iOS, where there is no Apple Health to read — every health
    // surface checks this first.
    final bool health = ref.watch(healthAvailableProvider);

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
          childAspectRatio: cellAspectRatio,
          mainAxisSpacing: SdContentPaddingV2.listItemGap,
          crossAxisSpacing: SdContentPaddingV2.listItemGap,
          // A scroll view with a null padding helps itself to the ambient
          // MediaQuery inset, so this one arrived with the device's safe area
          // on top of the screen padding the dashboard had already applied —
          // the notch's worth of blank space above the first row.
          padding: EdgeInsets.zero,
          // The dashboard's own list owns the scrolling.
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            DashboardExploreCard(
              icon: Icons.notifications_active_outlined,
              title: l10n.dashboardReminderTitle,
              content: DashboardExploreSubtitle(l10n.dashboardReminderBody),
              onTap: () => context.goNamed(AppRoutes.medications.name),
            ),
            DashboardExploreCard(
              // Distinct from the bottom nav's insights_outlined so byIcon
              // finders stay unambiguous.
              icon: Icons.analytics_outlined,
              title: l10n.dashboardInsightsBannerTitle,
              content: DashboardExploreSubtitle(
                l10n.dashboardInsightsBannerBody,
              ),
              onTap: () => context.goNamed(AppRoutes.insights.name),
            ),
            if (health) ...<Widget>[
              const DashboardSleepCard(),
              const DashboardStepsCard(),
            ],
            DashboardExploreCard(
              icon: Icons.ios_share_outlined,
              title: l10n.dashboardExportTitle,
              content: DashboardExploreSubtitle(l10n.dashboardExportBody),
              // Straight to Export — landing on Settings and hunting isn't
              // what the card promised.
              onTap: () => context.pushNamed(AppRoutes.export.name),
            ),
          ],
        ),
      ],
    );
  }
}
