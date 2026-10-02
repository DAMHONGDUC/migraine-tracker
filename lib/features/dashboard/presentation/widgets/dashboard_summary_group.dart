import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../insights/providers.dart';
import 'dashboard_severity_card.dart';
import 'month_days_card.dart';
import 'week_summary_card.dart';

/// The week count and this month's migraine days side by side, the severity mix under them, nested inside one outer card.
///
/// **Week and month are a pair, one row, equal height** (2026-09-30 redesign).
/// Stacked, the two counts sat a card apart and read as two unrelated figures;
/// side by side they read as the same history at two widths, which is what they
/// are. Equal height is the dashboard's own rule for a set of cards.
class DashboardSummaryGroup extends ConsumerWidget {
  const DashboardSummaryGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Asked here, not left to the card: a month card that hid itself inside the row would leave the week at half width beside nothing.
    final bool hasMonth = ref.watch(migraineDaysProvider).currentMonth != null;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w12),
        child: Column(
          children: [
            if (hasMonth)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: WeekSummaryCard()),
                    SizedBox(width: SdSpacingConstant.w12),
                    const Expanded(child: MonthDaysCard()),
                  ],
                ),
              )
            else
              const WeekSummaryCard(),
            SizedBox(height: SdSpacingConstant.h12),
            const DashboardSeverityCard(),
          ],
        ),
      ),
    );
  }
}
