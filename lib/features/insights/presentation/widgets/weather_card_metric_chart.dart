part of 'weather_card.dart';

/// The picked reading drawn under its own hours — the shape iOS Weather uses,
/// where the hourly row IS the chart's x axis rather than a second copy of it.
///
/// **It draws no axes and no grid, on purpose.** Every number is already
/// printed in the cell directly above its mark, so a left axis would restate
/// the lot. What the chart adds is the one thing the row cannot say: the shape
/// of the day.
///
/// **It does carry a tooltip** (owner's call, reversing the same "the number
/// is already above it" reasoning). Touch-and-hold names the hour and its
/// reading in the wording the cell uses, from the same two calls, so the
/// bubble can never disagree with the strip. `ExcludeSemantics` still stands:
/// VoiceOver reads the cells, which say everything the bubble does.
///
/// **The tooltip does not cost the strip its scroll.** `fl_chart` registers a
/// `PanGestureRecognizer`, which competes with the horizontal scroll view
/// around it — but pan needs `kPanSlop` (36) where a horizontal drag needs
/// `kTouchSlop` (18), so a sideways swipe resolves to the scroll first and
/// only a press that stays put reaches the chart.
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

  /// Tall enough to hold its own against the width the region now has —
  /// a plot this wide at a lesser height flattened every day into a smear.
  /// Still under the cells above it, which stay the card's headline, and the
  /// room the smaller hour glyphs gave back went here.
  static double get height => SdSpacingConstant.h108;

  static double get barWidth => SdSpacingConstant.w12;

  /// Half a cell of overhang either side: this is what puts x = i on the
  /// centre of cell i instead of on its leading edge.
  double get minX => -0.5;

  double get maxX => hours.length - 0.5;

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
            ? _bars(context, range)
            : _line(context, range),
      ),
    );
  }

  /// The bubble's text: the reading over the hour it belongs to, worded by the
  /// same two calls the cell above uses — so the two can never disagree.
  ///
  /// Null for an hour Apple had no value for; its cell shows an em dash and a
  /// bubble saying nothing is worse than no bubble.
  String? _tooltip(AppLocalizations l10n, int index) {
    final WeatherHourly hour = hours[index];
    final String? value = WeatherMetricUtils.value(l10n, metric, hour);
    final bool isNow =
        index == 0 && DateTimeUtils.isSameDay(hour.time, DateTime.now());

    if (value == null) return null;

    return '$value\n'
        '${isNow ? l10n.weatherNow : DateFormat.j().format(hour.time.toLocal())}';
  }

  /// An x back to the hour it belongs to.
  ///
  /// Rounded and clamped, because the line carries two synthetic spots — the
  /// ones held out to [minX] and [maxX] to close the end gaps — and those must
  /// report the real hour they were copied from rather than an index off the
  /// end of the list.
  int _hourAt(double x) => x.round().clamp(0, hours.length - 1);

  /// Rain and UV: one rod per hour, every hour.
  ///
  /// **An hour with no value keeps a rod and turns it invisible — it must
  /// never be an empty group.** `spaceAround` spreads the leftover width over
  /// the groups it has, so a group of width 0 widens every gap and slides
  /// every other column off the cell it belongs to.
  Widget _bars(BuildContext context, (double min, double max) range) {
    final AppLocalizations l10n = context.l10n;

    return BarChart(
      BarChartData(
        // With every group the same width, equal space around each puts group i
        // at the centre of cell i — the same place the line chart's x = i lands.
        alignment: BarChartAlignment.spaceAround,
        minY: range.$1,
        maxY: range.$2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => SdChartStyleV2.tooltipBackground(context),
            // Null for the invisible placeholder rod — it holds a slot, it is
            // not a reading, and a bubble on it would claim one.
            getTooltipItem:
                (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  final String? text = _tooltip(l10n, group.x);

                  return text == null
                      ? null
                      : BarTooltipItem(
                          text,
                          SdChartStyleV2.tooltipLabel(context),
                        );
                },
          ),
        ),
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
  }

  /// Holds the first and last readings flat out to the chart's own edges.
  ///
  /// **Because points sit on cell centres, the curve otherwise starts half a
  /// cell in at each end** and the card reads as if the chart carried a
  /// horizontal inset of its own on top of the card's. Extending the outermost
  /// run to the edge closes that without moving a single real point.
  ///
  /// **Only where the data actually reaches the end.** A run that starts after
  /// hour 0 does so because Apple had no value there, and stretching it would
  /// paint over exactly the gap the segments exist to show.
  List<List<FlSpot>> _toEdges(List<List<FlSpot>> segments) {
    if (segments.isEmpty) return segments;

    final List<FlSpot> first = segments.first;
    final List<FlSpot> last = segments.last;

    if (first.first.x == 0) first.insert(0, FlSpot(minX, first.first.y));
    if (last.last.x == hours.length - 1) last.add(FlSpot(maxX, last.last.y));

    return segments;
  }

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
    final AppLocalizations l10n = context.l10n;
    final List<List<FlSpot>> segments = _toEdges(
      WeatherMetricUtils.segments(metric, hours),
    );

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: range.$1,
        maxY: range.$2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => SdChartStyleV2.tooltipBackground(context),
            getTooltipItems: (List<LineBarSpot> spots) => <LineTooltipItem?>[
              for (final LineBarSpot spot in spots)
                if (_tooltip(l10n, _hourAt(spot.x)) case final String text)
                  LineTooltipItem(text, SdChartStyleV2.tooltipLabel(context))
                else
                  null,
            ],
          ),
        ),
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
              // A gradient dying into the card, not a flat wash: at this
              // height a single alpha reads as a solid block with a line on
              // top, and the eye stops following the curve.
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.chartSeries.withValues(alpha: 0.22),
                    AppColors.chartSeries.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
