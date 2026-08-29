import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_text_style.dart';

/// Label left, figure right. The label takes the slack so a long translation wraps instead of pushing the number off the card.
class InsightValueRow extends StatelessWidget {
  const InsightValueRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyle.bodyMedium.secondary)),
        SizedBox(width: SdSpacingConstant.w12),
        Text(value, style: AppTextStyle.bodyMedium.w600),
      ],
    );
  }
}
