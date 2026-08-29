import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// One cell of the dashboard's explore grid: glyph, name, and whatever the card has to say under them.
class DashboardExploreCard extends StatelessWidget {
  const DashboardExploreCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
    this.trailing,
    super.key,
  });

  /// The header row's height, reserved for every cell whether or not it has a [trailing].
  static double get headerHeight => AppIconSize.row + SdSpacingConstant.h4;

  final IconData icon;
  final String title;
  final Widget content;
  final VoidCallback onTap;

  /// Sits at the end of the header row, opposite the glyph. Null on the cards that have nothing to say there.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        // Tighter than a full-width card's w16, like the quick-access tiles above.
        padding: EdgeInsets.all(SdSpacingConstant.w12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // - a bare glyph, not a tinted badge.
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
          // Expanded keeps every grid cell within its assigned square.
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
      // Two, and the cell is sized for exactly two — a third line would clip rather than grow the box.
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
