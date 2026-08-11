part of 'weather_card.dart';

/// The card's default face: pressure over the hours ahead.
///
/// Pressure and not temperature, on the one card whose lower half is the
/// pressure alert — the line and the threshold that fires on it read as one
/// thing, which is the whole reason the alert moved onto this card.
///
/// Drawn from the report's own hours, so it costs no extra fetch.
class _PressureChart extends StatelessWidget {
  const _PressureChart({required this.hours});

  final List<WeatherHourly> hours;

  /// Two days, matching the window the report asks for.
  static const int _maxHours = 48;

  /// Hours between axis labels. Six keeps them legible across 48 hours.
  static const double _labelInterval = 6;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<WeatherHourly> shown = hours.take(_maxHours).toList();

    if (shown.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    final DateTime start = shown.first.time;
    final DateFormat timeFormat = DateFormat.Hm(l10n.localeName);
    final TextStyle labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: SdSpacingConstant.sp10,
    );
    final List<FlSpot> spots = <FlSpot>[
      for (final WeatherHourly hour in shown)
        FlSpot(
          DateTimeUtils.hoursBetween(start, hour.time),
          hour.pressureHpa,
        ),
    ];
    final Iterable<double> pressures = shown.map(
      (WeatherHourly h) => h.pressureHpa,
    );
    final double minY = ChartAxisUtils.minBound(pressures);
    final double maxY = ChartAxisUtils.maxBound(pressures);
    // One interval for the grid and the axis labels both — computing it twice
    // is how the two drift apart.
    final double gridInterval = ChartAxisUtils.interval(minY, maxY);

    return Semantics(
      label: l10n.a11yForecastChart(
        spots.first.y.toStringAsFixed(0),
        spots.map((FlSpot s) => s.y).reduce(min).toStringAsFixed(0),
      ),
      // Chart pixels say nothing to VoiceOver; the label above stands in.
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
                getDrawingHorizontalLine: (double _) =>
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
                    getTitlesWidget: (double value, TitleMeta _) =>
                        Text(value.toInt().toString(), style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _labelInterval,
                    reservedSize: SdSpacingConstant.h24,
                    getTitlesWidget: (double value, TitleMeta _) => Padding(
                      padding: EdgeInsets.only(top: SdSpacingConstant.h6),
                      child: Text(
                        value == 0
                            ? l10n.weatherNow
                            : timeFormat.format(
                                DateTimeUtils.timeAt(start, value).toLocal(),
                              ),
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceElevated,
                  getTooltipItems: (List<LineBarSpot> touched) =>
                      <LineTooltipItem>[
                        for (final LineBarSpot spot in touched)
                          LineTooltipItem(
                            '${l10n.insightsPressureValue(spot.y.toStringAsFixed(1))}\n'
                            '${timeFormat.format(DateTimeUtils.timeAt(start, spot.x).toLocal())}',
                            AppTextStyle.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                ),
              ),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: spots,
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
