import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/services/weekly_buckets.dart';

/// Single-series weekly bar chart. Follows the chart specs: thin rounded
/// bars, recessive horizontal grid, muted text labels, touch tooltip; no
/// legend (the title names the one series).
class WeeklyFrequencyChart extends StatelessWidget {
  const WeeklyFrequencyChart({required this.buckets, super.key});

  final List<WeeklyBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount = buckets.fold(0, (m, b) => max(m, b.count));
    final interval = maxCount <= 4 ? 1.0 : (maxCount / 4).ceilToDouble();
    final labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: AppSpacingConstant.sp10,
    );
    final weekLabel = DateFormat.Md(context.l10n.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.historyChartTitle,
          style: AppTextStyle.titleMedium,
        ),
        SizedBox(height: AppSpacingConstant.h12),
        // Bars are unreadable to VoiceOver — summarise the series instead.
        Semantics(
          label: context.l10n.a11yWeeklyChart(
            buckets.fold(0, (sum, b) => sum + b.count),
            buckets.length,
          ),
          child: ExcludeSemantics(
            child: SizedBox(
          height: AppSpacingConstant.h160,
          child: BarChart(
            BarChartData(
              maxY: max(maxCount, 1) + 0.5,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: AppColors.chartGrid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    reservedSize: AppSpacingConstant.w28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: labelStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: AppSpacingConstant.h24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      // Label every other week to avoid collisions.
                      if (index.isOdd || index >= buckets.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: AppSpacingConstant.h6),
                        child: Text(
                          weekLabel.format(buckets[index].weekStart),
                          style: labelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceElevated,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        context.l10n.historyChartTooltip(rod.toY.toInt()),
                        AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (final (index, bucket) in buckets.indexed)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bucket.count.toDouble(),
                        width: AppSpacingConstant.w14,
                        color: AppColors.chartSeries,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSpacingConstant.r4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
          ),
        ),
      ],
    );
  }
}
