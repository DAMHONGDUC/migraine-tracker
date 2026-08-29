import 'package:flutter/material.dart';
import 'package:system_design/index.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';

/// The "there is more inside" mark every dashboard card that opens something wears at its trailing edge.
class DashboardChevron extends StatelessWidget {
  const DashboardChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return SdIconV2(
      icon: AppIconConstant.disclosure,
      size: AppIconSize.affordance,
      color: context.colorScheme.onSurfaceVariant,
    );
  }
}
