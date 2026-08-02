import 'package:flutter/material.dart';
import 'package:system_design/v2/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/history_period.dart';

/// The period filter pill (icon + current value + expand chevron); tapping
/// opens the bottom sheet. Rendered at the top of the list/chart content,
/// below the app bar. A thin [SdFilterChipV2] wrapper — see that class for
/// the shared visuals/behavior now also used by the medications tab.
class HistoryFilterChip extends StatelessWidget {
  const HistoryFilterChip({
    required this.selected,
    required this.onSelected,
    this.count,
    super.key,
  });

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;

  /// How many attacks the selected period matches — shown as "All (10)".
  final int? count;

  /// Localized label for a period (used for both the current value and each
  /// option in the filter sheet).
  static String _label(BuildContext context, HistoryPeriod period) =>
      switch (period) {
        HistoryPeriod.today => context.l10n.historyFilterToday,
        HistoryPeriod.week => context.l10n.historyFilterWeek,
        HistoryPeriod.month => context.l10n.historyFilterMonth,
        HistoryPeriod.year => context.l10n.historyFilterYear,
        HistoryPeriod.all => context.l10n.historyFilterAll,
      };

  @override
  Widget build(BuildContext context) {
    return SdFilterChipV2<HistoryPeriod>(
      label: _label(context, selected),
      selected: selected,
      options: HistoryPeriod.values,
      optionLabelBuilder: (period) => _label(context, period),
      onSelected: onSelected,
      sheetTitle: context.l10n.historyFilterSheetTitle,
      count: count,
      countLabelBuilder: (label, count) =>
          context.l10n.historyFilterWithCount(label, count),
    );
  }
}
