import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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
  return showAppBottomSheet<HistoryPeriod>(
    context,
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
      borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
        onTap: () => _open(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w14, vertical: AppSpacingConstant.h8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: AppSpacingConstant.r16, color: scheme.primary),
              SizedBox(width: AppSpacingConstant.w6),
              Text(
                periodLabel(context, selected),
                style: context.textTheme.labelLarge,
              ),
              SizedBox(width: AppSpacingConstant.w2),
              Icon(
                Icons.expand_more,
                size: AppSpacingConstant.r18,
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
            padding: EdgeInsets.fromLTRB(AppSpacingConstant.w24, AppSpacingConstant.h4, AppSpacingConstant.w24, AppSpacingConstant.h12),
            child: Text(
              context.l10n.historyFilterSheetTitle,
              style: context.textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final period in HistoryPeriod.values)
                  ListTile(
                    leading: Icon(
                      period == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: period == selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      size: AppSpacingConstant.r22,
                    ),
                    title: Text(periodLabel(context, period)),
                    onTap: () => Navigator.of(context).pop(period),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacingConstant.h8),
        ],
      ),
    );
  }
}
