import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/history_period.dart';

/// Horizontal row of period filter chips. ChoiceChip animates its own
/// selected state; the list below cross-fades when the selection changes.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onSelected;

  String _label(BuildContext context, HistoryPeriod period) =>
      switch (period) {
        HistoryPeriod.today => context.l10n.historyFilterToday,
        HistoryPeriod.week => context.l10n.historyFilterWeek,
        HistoryPeriod.month => context.l10n.historyFilterMonth,
        HistoryPeriod.year => context.l10n.historyFilterYear,
        HistoryPeriod.all => context.l10n.historyFilterAll,
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          for (final period in HistoryPeriod.values) ...[
            ChoiceChip(
              label: Text(_label(context, period)),
              selected: selected == period,
              showCheckmark: false,
              onSelected: (_) => onSelected(period),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}
