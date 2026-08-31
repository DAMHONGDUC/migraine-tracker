import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The shape of an analysis that has not been computed yet.
///
/// **Only where the wait is real.** The correlation engines run over the local
/// database and settle in a frame or two, so a placeholder there would flash —
/// which hard rule 3 forbids outright. The bodies that use this one are
/// waiting on a HealthKit read, which takes as long as it takes.
///
/// A sentence, then the two figures under it: the same three shapes every one
/// of these bodies resolves into, so nothing moves when the numbers land.
class InsightBodySkeleton extends StatelessWidget {
  const InsightBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSkeletonV2.line(),
        SizedBox(height: SdSkeletonV2.lineGap),
        SdSkeletonV2.line(fraction: 0.6),
        SizedBox(height: SdSpacingConstant.h16),
        SdSkeletonV2(height: SdSpacingConstant.h44),
        SizedBox(height: SdContentPaddingV2.listItemGap),
        SdSkeletonV2(height: SdSpacingConstant.h44),
      ],
    );
  }
}
