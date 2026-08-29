import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import 'dashboard_severity_card.dart';
import 'month_days_card.dart';
import 'week_summary_card.dart';

/// The week count, this month's migraine days and the severity mix, nested inside one outer card.
class DashboardSummaryGroup extends ConsumerWidget {
  const DashboardSummaryGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w12),
        child: Column(
          children: [
            const WeekSummaryCard(),
            SizedBox(height: SdSpacingConstant.h12),
            // Week then month then severity: the same history at widening granularity, so the group reads in one direction.
            const MonthDaysCard(),
            SizedBox(height: SdSpacingConstant.h12),
            const DashboardSeverityCard(),
          ],
        ),
      ),
    );
  }
}
