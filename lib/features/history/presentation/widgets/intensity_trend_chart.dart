import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/services/chart_analytics.dart';

/// Line chart of average pain intensity per week (0–10). Weeks with no
/// attacks leave a gap rather than dropping the line to zero — only weeks that
/// actually had attacks become points. Same calm styling as the frequency
/// chart: recessive grid, muted labels, touch tooltip, no legend.
class IntensityTrendChart extends StatelessWidget {
  const IntensityTrendChart({required this.points, super.key});

  final List<IntensityTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: AppSpacingConstant.sp10,
    );
    final weekLabel = DateFormat.Md(l10n.localeName);

    final spots = [
      for (final (index, point) in points.indexed)
        if (point.average != null) FlSpot(index.toDouble(), point.average!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyChartIntensityTitle, style: AppTextStyle.titleMedium),
        SizedBox(height: AppSpacingConstant.h12),
        Semantics(
          label: l10n.a11yChart(l10n.historyChartIntensityTitle),
          child: ExcludeSemantics(
            child: SizedBox(
              height: AppSpacingConstant.h160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 2,
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
                        interval: 2,
                        reservedSize: AppSpacingConstant.w28,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString(), style: labelStyle),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: AppSpacingConstant.h24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index.isOdd || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: AppSpacingConstant.h6),
                            child: Text(
                              weekLabel.format(points[index].weekStart),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surfaceElevated,
                      getTooltipItems: (touched) => [
                        for (final spot in touched)
                          LineTooltipItem(
                            l10n.historyChartIntensityTooltip(
                              spot.y.toStringAsFixed(1),
                            ),
                            AppTextStyle.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: AppSpacingConstant.w2,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: AppSpacingConstant.r4,
                              color: AppColors.primary,
                              strokeWidth: 0,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
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
