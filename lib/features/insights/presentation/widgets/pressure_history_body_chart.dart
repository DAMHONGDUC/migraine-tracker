part of 'pressure_history_body.dart';

/// The pressure line with a dot on every day that ended in an attack.
class _Chart extends StatelessWidget {
  const _Chart({required this.timeline});

  final PressureTimeline timeline;

  /// Big enough to find with a thumb on a card-width axis, small enough that two on neighbouring days do not merge into one blob.
  static double get dotRadius => SdSpacingConstant.r4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextStyle labelStyle = AppTextStyle.bodySmall.copyWith(
      color: AppColors.textSecondary,
      fontSize: SdSpacingConstant.sp10,
    );
    final DateFormat dayFormat = DateFormat.Md(l10n.localeName);
    final List<PressureTimelineDay> days = timeline.days;
    final List<FlSpot> spots = <FlSpot>[
      for (final (int i, PressureTimelineDay day) in days.indexed)
        FlSpot(i.toDouble(), day.pressureHpa),
    ];
    final double minY = ChartAxisUtils.minBound(
      days.map((PressureTimelineDay d) => d.pressureHpa),
    );
    final double maxY = ChartAxisUtils.maxBound(
      days.map((PressureTimelineDay d) => d.pressureHpa),
    );
    // One interval for the grid and the axis labels both — computing it twice is how the two drift apart.
    final double gridInterval = ChartAxisUtils.interval(minY, maxY);
    // Roughly a label a week however many days actually carry a reading, so the axis never becomes a smear of dates.
    final double dayInterval = (days.length / 4).ceilToDouble().clamp(1, 30);

    return Semantics(
      label: l10n.a11yPressureHistoryChart(
        PressureTimelineBuilder.defaultWindowDays,
        timeline.attacksPlotted,
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
                getDrawingHorizontalLine: (_) =>
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
                    getTitlesWidget: (double value, _) =>
                        Text(value.toInt().toString(), style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: dayInterval,
                    reservedSize: SdSpacingConstant.h24,
                    getTitlesWidget: (double value, _) {
                      final int index = value.round();

                      if (index < 0 || index >= days.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: EdgeInsets.only(top: SdSpacingConstant.h6),
                        child: Text(
                          dayFormat.format(days[index].day),
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
                  getTooltipItems: (List<LineBarSpot> touched) => <
                    LineTooltipItem
                  >[
                    for (final LineBarSpot spot in touched)
                      LineTooltipItem(
                        '${l10n.insightsPressureValue(spot.y.toStringAsFixed(1))}\n'
                        '${dayFormat.format(days[spot.x.round()].day)}',
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
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.chartSeries.withValues(alpha: 0.08),
                  ),
                  dotData: FlDotData(
                    checkToShowDot: (FlSpot spot, _) =>
                        days[spot.x.round()].hasAttack,
                    getDotPainter: (FlSpot spot, _, _, _) {
                      final PressureTimelineDay day = days[spot.x.round()];

                      return FlDotCirclePainter(
                        radius: dotRadius,
                        color: AppColors.intensity(day.peakIntensity ?? 1),
                        strokeWidth: 1,
                        strokeColor: AppColors.surface,
                      );
                    },
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
