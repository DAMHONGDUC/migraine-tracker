import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/health_range.dart';

/// The D / W / M / 6M selector over a health chart.
///
/// One widget for both cards, so steps and sleep cannot end up offering
/// different windows. Single letters like Apple Health's own: four segments
/// share the card's width, and "6 months" spelled out does not fit one at the
/// design width in either locale.
class HealthRangeSelector extends StatelessWidget {
  const HealthRangeSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HealthRange selected;
  final ValueChanged<HealthRange> onSelected;

  static String label(AppLocalizations l10n, HealthRange range) =>
      switch (range) {
        HealthRange.day => l10n.healthRangeDay,
        HealthRange.week => l10n.healthRangeWeek,
        HealthRange.month => l10n.healthRangeMonth,
        HealthRange.halfYear => l10n.healthRangeHalfYear,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdSegmentedTabsV2(
      segments: <SdSegmentV2>[
        for (final HealthRange range in HealthRange.values)
          SdSegmentV2(label: label(l10n, range)),
      ],
      selectedIndex: HealthRange.values.indexOf(selected),
      onSelected: (int index) => onSelected(HealthRange.values[index]),
    );
  }
}
