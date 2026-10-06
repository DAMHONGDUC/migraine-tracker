import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icon_constant.dart';

/// The first pill of a filter strip: opens `AllFiltersSheet`, and says how
/// many axes are on — "Filters (2)" — highlighted while any is.
///
/// Its own glyph, so it is not read as one more axis among the chips after it.
class AllFiltersPill extends StatelessWidget {
  const AllFiltersPill({required this.count, required this.onTap, super.key});

  /// How many axes are narrowing the list.
  final int count;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String title = context.l10n.filtersSheetTitle;

    return SdFilterPillV2(
      icon: AppIconConstant.filtersAll,
      label: count == 0
          ? title
          : context.l10n.historyFilterWithCount(title, count),
      active: count > 0,
      onTap: onTap,
    );
  }
}
