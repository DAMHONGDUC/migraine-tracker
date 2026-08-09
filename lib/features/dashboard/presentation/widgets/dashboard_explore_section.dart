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
///
/// A two-column grid, two cards to a row, glyph above the label rather than
/// beside it — a tall card gives the subtitle a line of its own instead of the
/// sliver left over next to an icon badge. An odd last card fills one cell and
/// leaves the other empty, like any grid.
///
/// Laid out as stretched rows rather than a `GridView`: the cells hold text,
/// which a grid can only size by a fixed height or ratio, and Vietnamese plus
/// large accessibility sizes overflow whatever number is picked. Rows size
/// themselves to the tallest card and cannot clip.
class DashboardExploreSection extends StatelessWidget {
  const DashboardExploreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<_ExploreCard> cards = <_ExploreCard>[
      _ExploreCard(
        icon: Icons.notifications_active_outlined,
        title: l10n.dashboardReminderTitle,
        subtitle: l10n.dashboardReminderBody,
        onTap: () => context.goNamed(AppRoutes.medications.name),
      ),
      _ExploreCard(
        // Distinct from the bottom nav's insights_outlined so byIcon finders
        // stay unambiguous.
        icon: Icons.analytics_outlined,
        title: l10n.dashboardInsightsBannerTitle,
        subtitle: l10n.dashboardInsightsBannerBody,
        onTap: () => context.goNamed(AppRoutes.insights.name),
      ),
      _ExploreCard(
        icon: Icons.ios_share_outlined,
        title: l10n.dashboardExportTitle,
        subtitle: l10n.dashboardExportBody,
        // Straight to Export — landing on Settings and hunting isn't what the
        // card promised.
        onTap: () => context.pushNamed(AppRoutes.export.name),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: SdSpacingConstant.w4),
          child: Text(
            l10n.dashboardExplore.toUpperCase(),
            style: AppTextStyle.labelSmall.secondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        for (int start = 0; start < cards.length; start += 2) ...[
          if (start > 0) SizedBox(height: SdContentPaddingV2.listItemGap),
          _ExploreRow(
            start: cards[start],
            end: start + 1 < cards.length ? cards[start + 1] : null,
          ),
        ],
      ],
    );
  }
}

/// One row of the grid. [end] is null on an odd last row, where the empty cell
/// still takes its half so the lone card stays the width of every other one.
class _ExploreRow extends StatelessWidget {
  const _ExploreRow({required this.start, required this.end});

  final Widget start;
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: start),
          SizedBox(width: SdContentPaddingV2.listItemGap),
          Expanded(child: end ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A bare glyph, not a tinted badge: at two cards a row the badge's
            // disc was most of the card's top edge.
            SdIconV2(
              icon: icon,
              size: SdSpacingConstant.r24,
              color: AppColors.primary,
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Text(title, style: AppTextStyle.titleMedium.w600),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              subtitle,
              style: AppTextStyle.bodySmall.secondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
