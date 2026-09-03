part of 'pressure_history_body.dart';

/// The pressure line, with every attack sitting at the hour it started.
///
/// An attack that carries its own snapshot is drawn at that hour and at the
/// pressure it was taken at — the day's dot only stands in for the ones logged
/// before snapshots existed, or offline where the backfill never landed.
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
    // Date and hour together: an attack's mark is only meaningful beside the day it fell on.
    final DateFormat hourFormat = DateFormat.Md(
      l10n.localeName,
    ).addPattern(DateFormat.HOUR_MINUTE, ' ');
    final List<PressureTimelineDay> days = timeline.days;
    final List<FlSpot> spots = <FlSpot>[
      for (final (int i, PressureTimelineDay day) in days.indexed)
        FlSpot(i.toDouble(), day.pressureHpa),
    ];
    final List<PressureTimelineMoment> moments = timeline.moments;
    // Days whose attacks are all placed by the hour keep no dot of their own — two marks for one attack reads as two attacks.
    final Set<int> hourlyDays = <int>{
      for (final PressureTimelineMoment moment in moments) moment.x.floor(),
    };
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
                        // An hourly mark names its hour; the day line names its day. Rounding a fractional x onto the day list would name the wrong day either side of midday.
                        '${spot.barIndex == 1 && spot.spotIndex < moments.length ? hourFormat.format(moments[spot.spotIndex].at) : dayFormat.format(days[spot.x.round().clamp(0, days.length - 1)].day)}',
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
                        days[spot.x.round()].hasAttack &&
                        !hourlyDays.contains(spot.x.round()),
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
                // The hourly marks: dots only, no line. `show: false` keeps fl_chart from joining one attack to the next as if they were a series.
                if (moments.isNotEmpty)
                  LineChartBarData(
                    show: false,
                    spots: <FlSpot>[
                      for (final PressureTimelineMoment moment in moments)
                        FlSpot(moment.x, moment.pressureHpa),
                    ],
                    dotData: FlDotData(
                      getDotPainter: (FlSpot spot, _, _, int index) =>
                          FlDotCirclePainter(
                            radius: dotRadius,
                            color: AppColors.intensity(
                              moments[index].intensity,
                            ),
                            strokeWidth: 1,
                            strokeColor: AppColors.surface,
                          ),
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
