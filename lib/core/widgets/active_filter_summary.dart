import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';

/// The line above a filtered list saying how much of it is being hidden, and
/// offering the one tap that gives all of it back.
///
/// **A highlighted chip says which axis is on; only this says how many are.**
/// A strip of thirteen chips scrolls sideways, so the two that are narrowing
/// the list can both be off screen at once — and an empty list with no
/// explanation reads as an empty history rather than as a filter.
///
/// Shared by History and the medications tab so the two cannot word the same
/// count differently.
class ActiveFilterSummary extends StatelessWidget {
  const ActiveFilterSummary({
    required this.count,
    required this.onClear,
    super.key,
  });

  final int count;

  /// Puts every axis back to "all".
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    // Nothing filtered is nothing to say; a line reading "0 filters" is noise on every unfiltered screen.
    if (count == 0) return const SizedBox.shrink();

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.l10n.filtersAppliedCount(count),
            style: AppTextStyle.bodySmall.secondary,
          ),
        ),
        SdTextActionV2(
          label: context.l10n.filtersClearAll,
          // The row is already spaced by the list gap around it.
          padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
          onTap: onClear,
        ),
      ],
    );
  }
}
