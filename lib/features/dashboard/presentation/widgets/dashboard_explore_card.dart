import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// One cell of the dashboard's explore grid: glyph, name, and whatever the
/// card has to say under them.
///
/// Every cell is the same size — the grid gives them all one height — so what
/// varies is only [content], never the box. That is what makes the cards read
/// as one set rather than several differently shaped objects.
///
/// [content] is a slot rather than a pile of optional fields — today every
/// card puts a sentence there ([DashboardExploreSubtitle]), but the slot is
/// what let the health cards carry a reading before they moved out. [trailing]
/// is the same idea on the header row, and today it carries one thing: the
/// `PremiumBadge` on the export card.
class DashboardExploreCard extends StatelessWidget {
  const DashboardExploreCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
    this.trailing,
    super.key,
  });

  /// The header row's height, reserved for every cell whether or not it has a
  /// [trailing]. Stated as the glyph plus slack, so it moves when the glyph
  /// does: a `PremiumBadge` is a line of `labelSmall` inside its own h4
  /// padding — a shade taller than the icon beside it — and the grid's fixed
  /// cell cannot grow for it. [DashboardExploreSection.cellHeight] reads this
  /// rather than the glyph size.
  static double get headerHeight => AppIconSize.row + SdSpacingConstant.h4;

  final IconData icon;
  final String title;
  final Widget content;
  final VoidCallback onTap;

  /// Sits at the end of the header row, opposite the glyph. Null on the cards
  /// that have nothing to say there.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        // Tighter than a full-width card's w16, like the quick-access tiles
        // above: half a screen wide, the cell can spend the room on its
        // content or on its own margins, not on both.
        padding: EdgeInsets.all(SdSpacingConstant.w12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // - a bare glyph, not a tinted badge: at two cards a row the disc was most of the card's top edge
            // - AppIconSize.row, a step under the quick-access tiles: at half a screen wide, beside a title and two lines of subtitle, the glyph marks the card rather than being it
            Row(
              children: <Widget>[
                SdIconV2(
                  icon: icon,
                  size: AppIconSize.row,
                  color: AppColors.primary,
                ),
                const Spacer(),
                if (trailing case final Widget badge) badge,
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              title,
              style: AppTextStyle.titleMedium.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SdSpacingConstant.h4),
            // Expanded, so a cell whose content is shorter than the square
            // simply has room left over, and one that is longer clips inside
            // its own box instead of overflowing the grid.
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// What a navigational card says under its name.
class DashboardExploreSubtitle extends StatelessWidget {
  const DashboardExploreSubtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyle.bodySmall.secondary,
      // Two, and the cell is sized for exactly two — a third line would clip
      // rather than grow the box.
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
