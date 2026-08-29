import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';


/// An insight that cannot be computed yet, shown as the road to it rather
/// than a locked door: what is still missing, how far along it is, and the
/// count behind the bar.
class InsightProgressBody extends StatelessWidget {
  const InsightProgressBody({
    required this.icon,
    required this.message,
    required this.progress,
    required this.caption,
    super.key,
  });

  final IconData icon;

  /// What is still missing, already localized.
  final String message;

  /// How far along, clamped here so a caller that over-counts can't overflow
  /// the bar.
  final double progress;

  /// The counts behind the bar ("12 of 15"), already localized.
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdIconV2(
              icon: icon,
              size: AppIconSize.row,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Expanded(
              child: Text(message, style: AppTextStyle.bodyMedium),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: SdSpacingConstant.h6,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r3),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(caption, style: AppTextStyle.bodySmall.secondary),
      ],
    );
  }
}
