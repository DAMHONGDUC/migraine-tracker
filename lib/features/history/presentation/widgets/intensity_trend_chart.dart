import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/services/chart_analytics.dart';

/// Line chart of average pain intensity per week (0–10). Weeks with no
/// attacks leave a gap rather than dropping the line to zero — only weeks that
/// actually had attacks become points. Same calm styling as the frequency
/// chart: recessive grid, muted labels, touch tooltip, no legend.
class IntensityTrendChart extends StatelessWidget {
  const IntensityTrendChart({required this.points, super.key});

  /// The 0–10 pain scale is fixed, so the axis is too — a trend that rescales
  /// itself week to week would read as movement that isn't there.
  static const double maxIntensity = 10;
  static const double gridInterval = 2;

  final List<IntensityTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateFormat weekLabel = DateFormat.Md(l10n.localeName);
    final List<FlSpot> spots = <FlSpot>[
      for (final (int index, IntensityTrendPoint point) in points.indexed)
        if (point.average != null) FlSpot(index.toDouble(), point.average!),
    ];

    return SdChartFrameV2(
      title: l10n.historyChartIntensityTitle,
      semanticsLabel: l10n.a11yChart(l10n.historyChartIntensityTitle),
      height: SdChartStyleV2.plotHeight,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxIntensity,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: SdChartStyleV2.horizontalGrid(context, gridInterval),
          borderData: FlBorderData(show: false),
          titlesData: SdChartStyleV2.titles(
            left: SdChartStyleV2.countLeftTitles(context, gridInterval),
            // Label every other week to avoid collisions.
            bottom: SdChartStyleV2.categoryBottomTitles(context, 
              (int index) => index.isOdd || index >= points.length
                  ? null
                  : weekLabel.format(points[index].weekStart),
              interval: 1,
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => SdChartStyleV2.tooltipBackground(context),
              getTooltipItems: (List<LineBarSpot> touched) => <LineTooltipItem>[
                for (final LineBarSpot spot in touched)
                  LineTooltipItem(
                    l10n.historyChartIntensityTooltip(
                      spot.y.toStringAsFixed(1),
                    ),
                    SdChartStyleV2.tooltipLabel(context),
                  ),
              ],
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.primary,
              barWidth: SdSpacingConstant.w2,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: SdSpacingConstant.r4,
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
    );
  }
}
