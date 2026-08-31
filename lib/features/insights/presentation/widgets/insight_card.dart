import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// The shell every insight on the Insights screen wears: a card with its title, then the body that says what the analysis found.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.child,
    this.title,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Null on a card the tab strip above already names — a heading repeating the segment over it is a line of nothing. [trailing] still shows, on a row of its own.
  final String? title;
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
            // A card with nothing to put on that row skips it entirely, rather than opening on 16pt of empty.
            if (title != null || trailing != null || onTap != null) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Text(title!, style: AppTextStyle.titleMedium),
                  ),
                  ?trailing,
                  if (onTap != null)
                    SdIconV2(
                      icon: AppIconConstant.disclosure,
                      size: AppIconSize.small,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              SizedBox(height: SdSpacingConstant.h16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
