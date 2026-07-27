import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/chart_labels.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/services/chart_analytics.dart';

/// Bar chart of attacks by quarter of the day (night / morning / afternoon /
/// evening). Teal series to set it apart from the lavender frequency bars,
/// same calm grid + tooltip language.
class TimeOfDayChart extends StatelessWidget {
  const TimeOfDayChart({required this.counts, super.key});

  final List<DayPartCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxCount = counts.fold(0, (m, c) => max(m, c.count));
    final interval = maxCount <= 4 ? 1.0 : (maxCount / 4).ceilToDouble();
    final labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: AppSpacingConstant.sp10,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyChartTimeTitle, style: AppTextStyle.titleMedium),
        SizedBox(height: AppSpacingConstant.h12),
        Semantics(
          label: l10n.a11yChart(l10n.historyChartTimeTitle),
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
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.chartGrid,
                      strokeWidth: 1,
                    ),
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
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString(), style: labelStyle),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: AppSpacingConstant.h24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= counts.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              top: AppSpacingConstant.h6,
                            ),
                            child: Text(
                              counts[index].part.label(l10n),
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
                            l10n.historyChartTooltip(rod.toY.toInt()),
                            AppTextStyle.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                    ),
                  ),
                  barGroups: [
                    for (final (index, entry) in counts.indexed)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.count.toDouble(),
                            width: AppSpacingConstant.w20,
                            color: AppColors.secondary,
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
