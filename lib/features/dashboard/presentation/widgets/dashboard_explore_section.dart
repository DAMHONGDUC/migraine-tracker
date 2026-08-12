import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import 'dashboard_explore_card.dart';

/// Feature banners that surface capabilities living on other tabs —
/// reminders, insights, data export and About — each tapping straight
/// through.
///
/// Four of them, so the two-column grid comes out square: with three, the
/// last row carried one card and half a row of nothing.
///
/// **One grid, two to a row: every card is exactly the same size.**
/// Owner's rule, and it is why this is a `GridView`. It was hand-laid rows
/// before, which equalised height *within* a row but not across them, so
/// cards of different content read as unrelated pairs.
///
/// **The sleep and step cards are gone** (owner's call). They said what the
/// dashboard's Today section now says in one line each, and they were the
/// only cells carrying a reading and a button — which is what forced the
/// whole grid tall enough to hold one.
///
/// The cost of a fixed cell is the one the row layout existed to avoid: it
/// cannot grow for a long Vietnamese subtitle or a large accessibility text
/// size. Every cell therefore clips inside its own box rather than
/// overflowing the grid — see [DashboardExploreCard], where the content sits
/// in an `Expanded` and every string is capped with an ellipsis.
class DashboardExploreSection extends ConsumerWidget {
  const DashboardExploreSection({super.key});

  /// The cell's height, stated outright rather than derived from a ratio.
  ///
  /// A ratio ties height to whatever width is left over, which is how the
  /// weather card's details grid came to overflow. This is summed from what
  /// is actually in a cell: the padding, the glyph, the gaps, one line of
  /// title and two of subtitle.
  ///
  /// Much shorter than it was, because the health cards set the old floor —
  /// their figure plus a 48pt button could not go below ~156pt. Nothing left
  /// in the grid carries a button.
  static double get cellHeight =>
      SdSpacingConstant.h12 * 2 +
      SdSpacingConstant.r20 +
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
            DashboardExploreCard(
              icon: Icons.ios_share_outlined,
              title: l10n.dashboardExportTitle,
              content: DashboardExploreSubtitle(l10n.dashboardExportBody),
              // Straight to Export — landing on Settings and hunting isn't
              // what the card promised.
              onTap: () => context.pushNamed(AppRoutes.export.name),
            ),
            DashboardExploreCard(
              icon: Icons.info_outline,
              title: l10n.dashboardAboutTitle,
              content: DashboardExploreSubtitle(l10n.dashboardAboutBody),
              // Same screen the Settings row opens: the feature list and the
              // free plan's limits, which is what someone asking "what is
              // this" wants — not a marketing page.
              onTap: () => context.pushNamed(AppRoutes.about.name),
            ),
          ],
        ),
      ],
    );
  }
}
