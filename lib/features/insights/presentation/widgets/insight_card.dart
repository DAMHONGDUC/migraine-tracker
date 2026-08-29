import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// The shell every insight on the Insights screen wears: a card with its
/// title, then the body that says what the analysis found. [trailing] is for
/// a marker beside the title (the premium badge on a locked card); [onTap]
/// makes the whole card the way into a detail screen, and draws the chevron
/// that says so.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(title, style: AppTextStyle.titleMedium)),
                ?trailing,
                if (onTap != null)
                  SdIconV2(
                    icon: AppIconConstant.disclosure,
                    size: AppIconSize.affordance,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h16),
            child,
          ],
        ),
      ),
    );
  }
}
