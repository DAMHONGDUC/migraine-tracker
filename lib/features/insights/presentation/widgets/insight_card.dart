import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';

/// The shell every insight on the Insights screen wears: a card with its title, then the body that says what the analysis found.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.child,
    this.title,
    this.trailing,
    this.onInfo,
    this.onTap,
    super.key,
  });

  /// Null on a card the tab strip above already names — a heading repeating the segment over it is a line of nothing. [trailing] still shows, on a row of its own.
  final String? title;
  final Widget child;
  final Widget? trailing;

  /// Opens the sheet explaining what this card's analysis means.
  ///
  /// **Every analysis card has one** (owner's rule): a correlation states a
  /// relationship in one sentence, and the sentence alone never says what was
  /// compared against what, or why it is still empty. The glyph is quiet on
  /// purpose — it is there for the reader who stops, not a call to action.
  final VoidCallback? onInfo;

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
            if (title != null ||
                trailing != null ||
                onInfo != null ||
                onTap != null) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Text(title!, style: AppTextStyle.titleMedium),
                  ),
                  if (onInfo != null)
                    SdIconButtonV2(
                      icon: SdIconV2(
                        icon: AppIconConstant.info,
                        size: AppIconSize.small,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: context.l10n.insightsExplainTooltip,
                      onPressed: onInfo,
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
