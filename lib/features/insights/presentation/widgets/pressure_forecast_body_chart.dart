part of 'pressure_forecast_body.dart';

class _Chart extends StatelessWidget {
  const _Chart({required this.forecast});

  final PressureForecast forecast;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: SdSpacingConstant.sp10,
    );
    final timeFormat = DateFormat.Hm(context.l10n.localeName);

    final past = <FlSpot>[];
    final future = <FlSpot>[];
    for (final point in forecast.points) {
      final x = DateTimeUtils.hoursBetween(forecast.generatedAt, point.time);
      final spot = FlSpot(x, point.pressureHpa);
      if (x <= 0) past.add(spot);
      if (x >= 0) future.add(spot);
    }

    final pressures = forecast.points.map((p) => p.pressureHpa);
    final minY = ChartAxisUtils.minBound(pressures);
    final maxY = ChartAxisUtils.maxBound(pressures);
    // One interval for the grid and the axis labels both — computing it
    // twice is how the two drift apart.
    final gridInterval = ChartAxisUtils.interval(minY, maxY);

    DateTime timeAt(double x) =>
        DateTimeUtils.timeAt(forecast.generatedAt, x);

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
          height: SdSpacingConstant.h160,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: gridInterval,
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
                    interval: gridInterval,
                    reservedSize: SdSpacingConstant.w32,
                    getTitlesWidget: (value, meta) =>
                        Text(value.toInt().toString(), style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 12,
                    reservedSize: SdSpacingConstant.h24,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: EdgeInsets.only(top: SdSpacingConstant.h6),
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
