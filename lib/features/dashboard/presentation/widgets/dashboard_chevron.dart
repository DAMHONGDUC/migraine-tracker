import 'package:flutter/material.dart';
import 'package:system_design/index.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';

/// The "there is more inside" mark every dashboard card that opens something
/// wears at its trailing edge.
///
/// Owner's rule: a card the user can go into has to say so. The cards read as
/// readouts rather than as doors, and nothing but the chevron distinguishes
/// the two — the quick-access and explore grids are the exceptions, being
/// obviously a list of links already.
///
/// One widget rather than the recipe typed out per card: the three that had
/// it had already drifted, one of them onto a different colour.
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
