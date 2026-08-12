part of 'weather_card.dart';

/// The picked reading drawn under its own hours — the shape iOS Weather uses,
/// where the hourly row IS the chart's x axis rather than a second copy of it.
///
/// **It draws no axes, no grid and no tooltip, on purpose.** Every number is
/// already printed in the cell directly above its mark, so a left axis would
/// restate them, and a tooltip would restate them on tap. What the chart adds
/// is the one thing the row cannot say: the shape of the day.
///
/// **Alignment is the whole trick.** The parent states the width as
/// `_MetricCell.width * hours.length`, and the x range runs from `-0.5` to
/// `hours.length - 0.5` — which lands x = i on the centre of cell i exactly.
/// That is also why no axis may reserve space: `reservedSize` would shrink the
/// plot area and every column would drift off its cell.
class _MetricChart extends StatelessWidget {
  const _MetricChart({required this.hours, required this.metric});

  final List<WeatherHourly> hours;
  final WeatherMetric metric;

  /// Short by design: it sits under a strip that is already the tall half of
  /// the card, and the day's shape reads fine in this much.
  static double get height => SdSpacingConstant.h64;

  static double get barWidth => SdSpacingConstant.w8;

  @override
  Widget build(BuildContext context) {
    final List<double> values = <double>[
      for (final WeatherHourly hour in hours)
        if (WeatherMetricUtils.number(metric, hour) case final double value)
          value,
    ];

    // Apple gave this reading for none of the day's hours. The cells above
    // already say so, one em dash each — a chart of nothing would just be an
    // empty box under them.
    if (values.isEmpty) return const SizedBox.shrink();

    final (double min, double max) range = WeatherMetricUtils.range(
      metric,
      values,
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: WeatherMetricUtils.isBars(metric)
            ? _bars(range)
            : _line(context, range),
      ),
    );
  }

  /// Rain and UV: one rod per hour, every hour.
  ///
  /// **An hour with no value keeps a rod and turns it invisible — it must
  /// never be an empty group.** `spaceAround` spreads the leftover width over
  /// the groups it has, so a group of width 0 widens every gap and slides
  /// every other column off the cell it belongs to.
  Widget _bars((double min, double max) range) => BarChart(
    BarChartData(
      // With every group the same width, equal space around each puts group i
      // at the centre of cell i — the same place the line chart's x = i lands.
      alignment: BarChartAlignment.spaceAround,
      minY: range.$1,
      maxY: range.$2,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      barTouchData: BarTouchData(enabled: false),
      barGroups: <BarChartGroupData>[
        for (final (int index, WeatherHourly hour) in hours.indexed)
          BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              _rod(WeatherMetricUtils.number(metric, hour), range),
            ],
          ),
      ],
    ),
  );

  /// One hour's rod, or the placeholder that holds its slot when [value] is
  /// null: flat on the axis and fully transparent, so it takes width without
  /// claiming a reading of zero.
  BarChartRodData _rod(double? value, (double min, double max) range) =>
      BarChartRodData(
        toY: value ?? range.$1,
        width: barWidth,
        color: value == null
            ? AppColors.chartSeries.withValues(alpha: 0)
            : AppColors.chartSeries,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r3),
      );

  /// Temperature, wind, humidity, visibility: a curve, broken wherever Apple
  /// left a gap rather than drawn straight across it.
  Widget _line(BuildContext context, (double min, double max) range) {
    final List<List<FlSpot>> segments = WeatherMetricUtils.segments(
      metric,
      hours,
    );

    return LineChart(
      LineChartData(
        // Half a cell of overhang either side: this is what puts x = i on the
        // centre of cell i instead of on its leading edge.
        minX: -0.5,
        maxX: hours.length - 0.5,
        minY: range.$1,
        maxY: range.$2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: <LineChartBarData>[
          for (final List<FlSpot> segment in segments)
            LineChartBarData(
              spots: segment,
              color: AppColors.chartSeries,
              barWidth: SdSpacingConstant.h2,
              isCurved: true,
              curveSmoothness: 0.2,
              // A run of one has no line to draw, so it shows as a dot —
              // otherwise a lone reading between two gaps renders as nothing.
              dotData: FlDotData(show: segment.length == 1),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.chartSeries.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }
}
