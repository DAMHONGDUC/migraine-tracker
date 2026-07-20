import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../weather/domain/entities/pressure_forecast.dart';
import '../../../weather/providers.dart';

/// Single-series line chart: pressure over now−12h … now+48h. The dimmed
/// segment is the past, the solid one the forecast; a vertical marker
/// splits them at "now". No legend — the title names the one series.
class PressureForecastCard extends ConsumerWidget {
  const PressureForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(pressureForecastProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.insightsForecastTitle,
              style: AppTextStyle.titleMedium,
            ),
            SizedBox(height: AppSpacingConstant.h16),
            switch (forecast) {
              AsyncData(value: final value) when value != null => _Chart(
                forecast: value,
              ),
              AsyncLoading() => SizedBox(
                height: AppSpacingConstant.h160,
                child: const Center(child: CircularProgressIndicator()),
              ),
              _ => SizedBox(
                height: AppSpacingConstant.h64,
                child: Center(
                  child: Text(
                    context.l10n.insightsForecastUnavailable,
                    style: AppTextStyle.bodyMedium.secondary,
                  ),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.forecast});

  final PressureForecast forecast;

  double _hoursFromNow(DateTime time) =>
      time.difference(forecast.generatedAt).inMinutes / 60;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: AppSpacingConstant.sp10,
    );
    final timeFormat = DateFormat.Hm(context.l10n.localeName);

    final past = <FlSpot>[];
    final future = <FlSpot>[];
    for (final point in forecast.points) {
      final x = _hoursFromNow(point.time);
      final spot = FlSpot(x, point.pressureHpa);
      if (x <= 0) past.add(spot);
      if (x >= 0) future.add(spot);
    }

    final pressures = forecast.points.map((p) => p.pressureHpa);
    final minY = (pressures.reduce(min) - 2).floorToDouble();
    final maxY = (pressures.reduce(max) + 2).ceilToDouble();

    DateTime timeAt(double x) => forecast.generatedAt.add(
      Duration(minutes: (x * 60).round()),
    );

    // Chart pixels mean nothing to VoiceOver — describe the trend instead.
    final nowHpa = (past.isNotEmpty ? past.last.y : future.first.y);
    final minAheadHpa = future.map((s) => s.y).reduce(min);

    return Semantics(
      label: context.l10n.a11yForecastChart(
        nowHpa.toStringAsFixed(0),
        minAheadHpa.toStringAsFixed(0),
      ),
      child: ExcludeSemantics(
        child: SizedBox(
      height: AppSpacingConstant.h160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: max(((maxY - minY) / 3).ceilToDouble(), 1),
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
                interval: max(((maxY - minY) / 3).ceilToDouble(), 1),
                reservedSize: AppSpacingConstant.w32,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString(), style: labelStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 12,
                reservedSize: AppSpacingConstant.h24,
                getTitlesWidget: (value, meta) => Padding(
                  padding: EdgeInsets.only(top: AppSpacingConstant.h6),
                  child: Text(
                    value == 0
                        ? context.l10n.insightsForecastNow
                        : timeFormat.format(timeAt(value).toLocal()),
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: 0,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${context.l10n.insightsPressureValue(spot.y.toStringAsFixed(1))}\n'
                    '${timeFormat.format(timeAt(spot.x).toLocal())}',
                    AppTextStyle.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            // Past context — dimmed, no touch.
            LineChartBarData(
              spots: past,
              color: AppColors.chartSeries.withValues(alpha: 0.35),
              barWidth: 2,
              isCurved: true,
              curveSmoothness: 0.2,
              dotData: const FlDotData(show: false),
            ),
            // Forecast — the series the card is about.
            LineChartBarData(
              spots: future,
              color: AppColors.chartSeries,
              barWidth: 2,
              isCurved: true,
              curveSmoothness: 0.2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.chartSeries.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
