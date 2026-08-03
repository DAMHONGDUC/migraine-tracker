import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/weekly_buckets.dart';

/// Single-series weekly bar chart: how many attacks each week.
class WeeklyFrequencyChart extends StatelessWidget {
  const WeeklyFrequencyChart({required this.buckets, super.key});

  final List<WeeklyBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final DateFormat weekLabel = DateFormat.Md(context.l10n.localeName);

    return SdChartFrameV2(
      title: context.l10n.historyChartTitle,
      // Bars are unreadable to VoiceOver — summarise the series instead.
      semanticsLabel: context.l10n.a11yWeeklyChart(
        buckets.fold(0, (int sum, WeeklyBucket b) => sum + b.count),
        buckets.length,
      ),
      height: SdChartStyleV2.plotHeight,
      child: SdBarChartV2(
        bars: <SdBarV2>[
          for (final (int index, WeeklyBucket bucket) in buckets.indexed)
            SdBarV2(
              value: bucket.count.toDouble(),
              // Label every other week to avoid collisions.
              label: index.isOdd ? null : weekLabel.format(bucket.weekStart),
            ),
        ],
        color: AppColors.chartSeries,
        tooltip: (num value) => context.l10n.historyChartTooltip(value.toInt()),
      ),
    );
  }
}
