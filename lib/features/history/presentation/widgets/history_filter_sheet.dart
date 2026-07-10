import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';
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
/// Returns the picked period, or null when dismissed.
Future<HistoryPeriod?> showHistoryFilterSheet(
  BuildContext context, {
  required HistoryPeriod selected,
}) {
  return showModalBottomSheet<HistoryPeriod>(
    context: context,
    showDragHandle: true,
    builder: (_) => _FilterSheet(selected: selected),
  );
}

/// Chip below the app bar showing the active period; tapping opens the
/// bottom sheet. Closed = value at a glance, open = the full picker.
class HistoryFilterChip extends StatelessWidget {
  const HistoryFilterChip({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;

  Future<void> _open(BuildContext context) async {
    final picked = await showHistoryFilterSheet(context, selected: selected);
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () => _open(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 16.r, color: scheme.primary),
              SizedBox(width: 6.w),
              Text(
                periodLabel(context, selected),
                style: context.textTheme.labelLarge,
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.expand_more,
                size: 18.r,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.selected});

  final HistoryPeriod selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 12.h),
            child: Text(
              context.l10n.historyFilterSheetTitle,
              style: context.textTheme.titleMedium,
            ),
          ),
          for (final period in HistoryPeriod.values)
            ListTile(
              leading: Icon(
                period == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: period == selected
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                size: 22.r,
              ),
              title: Text(periodLabel(context, period)),
              onTap: () => Navigator.of(context).pop(period),
            ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
