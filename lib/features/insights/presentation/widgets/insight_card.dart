import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_text_style.dart';

/// The shell every insight on the Insights screen wears: a card with its
/// title, then the body that says what the analysis found. [trailing] is for
/// a marker beside the title (the premium badge on a locked card).
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(title, style: AppTextStyle.titleMedium)),
                ?trailing,
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
