import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// One cell of the dashboard's explore grid: glyph, name, and whatever the
/// card has to say under them.
///
/// Every cell is the same size — the grid gives them all one square — so what
/// varies is only [content], never the box. That is what makes five cards
/// read as one set rather than five differently shaped objects.
///
/// [content] is a slot rather than a pile of optional fields: a navigational
/// card puts a sentence there ([DashboardExploreSubtitle]), a health card puts
/// a reading and possibly a button ([DashboardExploreReading]).
class DashboardExploreCard extends StatelessWidget {
  const DashboardExploreCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // A bare glyph, not a tinted badge: at two cards a row the badge's
            // disc was most of the card's top edge.
            SdIconV2(
              icon: icon,
              size: SdSpacingConstant.r24,
              color: AppColors.primary,
            ),
            SizedBox(height: SdSpacingConstant.h12),
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
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// What a health card says under its name: the figure, and — while there is
/// still something to do before the figure means anything — the button that
/// leads to it.
class DashboardExploreReading extends StatelessWidget {
  const DashboardExploreReading({
    required this.value,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  /// Zero while locked or disconnected — a placeholder, never the user's own
  /// reading dressed down.
  final String value;

  /// Null once there is nothing left to do and the figure stands on its own.
  final String? actionLabel;

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final String? actionLabel = this.actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: AppTextStyle.titleLarge.w600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        if (actionLabel != null)
          SizedBox(
            width: double.infinity,
            child: SdButtonV2(
              variant: SdButtonVariantV2.secondary,
              size: SdButtonSizeV2.small,
              onPressed: onAction,
              label: actionLabel,
            ),
          ),
      ],
    );
  }
}
