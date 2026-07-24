import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_filter_sheet.dart';
import '../../domain/enums/history_period.dart';

String periodLabel(BuildContext context, HistoryPeriod period) =>
    switch (period) {
      HistoryPeriod.today => context.l10n.historyFilterToday,
      HistoryPeriod.week => context.l10n.historyFilterWeek,
      HistoryPeriod.month => context.l10n.historyFilterMonth,
      HistoryPeriod.year => context.l10n.historyFilterYear,
      HistoryPeriod.all => context.l10n.historyFilterAll,
    };

/// Opens the shared period filter (used by both list and chart modes).
/// Returns the picked period, or null when dismissed. Thin wrapper over the
/// generic [showAppFilterSheet] — see [HistoryFilterChip].
Future<HistoryPeriod?> showHistoryFilterSheet(
  BuildContext context, {
  required HistoryPeriod selected,
}) {
  return showAppFilterSheet<HistoryPeriod>(
    context,
    title: context.l10n.historyFilterSheetTitle,
    options: HistoryPeriod.values,
    selected: selected,
    labelBuilder: (period) => periodLabel(context, period),
  );
}

/// The period filter pill (icon + current value + expand chevron); tapping
/// opens the bottom sheet. Rendered at the top of the list/chart content,
/// below the app bar. A thin [AppFilterChip] wrapper — see that class for
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

  @override
  Widget build(BuildContext context) {
    return AppFilterChip<HistoryPeriod>(
      label: periodLabel(context, selected),
      selected: selected,
      options: HistoryPeriod.values,
      optionLabelBuilder: (period) => periodLabel(context, period),
      onSelected: onSelected,
      sheetTitle: context.l10n.historyFilterSheetTitle,
      count: count,
      countLabelBuilder: (label, count) =>
          context.l10n.historyFilterWithCount(label, count),
    );
  }
}
