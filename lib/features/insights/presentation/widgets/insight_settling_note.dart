import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';

/// The line under an insight whose sample has not reached its minimum: the figure above is real, it just still moves.
class InsightSettlingNote extends StatelessWidget {
  const InsightSettlingNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SdSpacingConstant.h4),
      child: Text(
        context.l10n.insightsStillSettling,
        style: AppTextStyle.bodySmall.secondary,
      ),
    );
  }
}
