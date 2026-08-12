part of 'weather_card.dart';

/// What the dropdown offers, and how each reading is worded and drawn.
///
/// Here rather than in `domain/`, because an `IconData` is a Flutter type and
/// `domain/` stays pure Dart.
final class WeatherMetricUtils {
  static String label(AppLocalizations l10n, WeatherMetric metric) =>
      switch (metric) {
        WeatherMetric.conditions => l10n.weatherMetricConditions,
        WeatherMetric.uvIndex => l10n.weatherDetailUv,
        WeatherMetric.wind => l10n.weatherDetailWind,
        WeatherMetric.precipitation => l10n.weatherDetailPrecipitation,
        WeatherMetric.humidity => l10n.weatherDetailHumidity,
        WeatherMetric.visibility => l10n.weatherDetailVisibility,
      };

  /// The reading for one hour, already localized, or null where Apple had no
  /// value for it — an hour showing nothing is honest, "0" would not be.
  static String? value(
    AppLocalizations l10n,
    WeatherMetric metric,
    WeatherHourly hour,
  ) => switch (metric) {
    WeatherMetric.conditions => WeatherConditionUtils.temperature(
      l10n,
      hour.temperatureCelsius,
    ),
    WeatherMetric.uvIndex => hour.uvIndex == null
        ? null
        : l10n.weatherUvValue(hour.uvIndex!.round()),
    WeatherMetric.wind => hour.windSpeedKph == null
        ? null
        : l10n.weatherWindValue(hour.windSpeedKph!.round()),
    WeatherMetric.precipitation => hour.precipitationChancePercent == null
        ? null
        : l10n.weatherPercent(hour.precipitationChancePercent!.round()),
    WeatherMetric.humidity => hour.humidityPercent == null
        ? null
        : l10n.weatherPercent(hour.humidityPercent!.round()),
    // Already kilometres off the wire, and rounded: a city block's
    // difference in visibility is not worth a decimal place.
    WeatherMetric.visibility => hour.visibilityKm == null
        ? null
        : l10n.weatherVisibilityValue(hour.visibilityKm!.round()),
  };

  /// The metric's own glyph, standing for the reading rather than for any
  /// one hour of it — what the picker shows when it is closed.
  ///
  /// Conditions takes a thermometer because that is what its cells actually
  /// read: the hour's temperature, with the sky drawn above it.
  static IconData glyph(WeatherMetric metric) => switch (metric) {
    WeatherMetric.conditions => Icons.thermostat,
    WeatherMetric.uvIndex => Icons.wb_sunny_outlined,
    WeatherMetric.wind => Icons.air,
    WeatherMetric.precipitation => Icons.umbrella_outlined,
    WeatherMetric.humidity => Icons.water_drop_outlined,
    WeatherMetric.visibility => Icons.visibility_outlined,
  };

  /// The glyph over an hour's value.
  ///
  /// Conditions vary hour to hour, so that one draws the hour's own weather;
  /// every other reading is a single quantity and reuses [glyph].
  static IconData icon(WeatherMetric metric, WeatherHourly hour) =>
      metric == WeatherMetric.conditions
      ? WeatherConditionUtils.icon(hour.condition)
      : glyph(metric);

  /// The top of the UV axis whatever the day holds — the WHO scale's own
  /// "extreme" band. Without a floor, a day peaking at 3 would draw a
  /// full-height curve and read as a dangerous one.
  static const double uvScaleTop = 11;

  /// The plotted number, unformatted.
  ///
  /// Deliberately beside [value], which prints the same field: a chart reading
  /// a different field from the label above it is the one bug this shape can
  /// have, and two switches in one class cannot drift unseen.
  static double? number(WeatherMetric metric, WeatherHourly hour) =>
      switch (metric) {
        WeatherMetric.conditions => hour.temperatureCelsius,
        WeatherMetric.uvIndex => hour.uvIndex,
        WeatherMetric.wind => hour.windSpeedKph,
        WeatherMetric.precipitation => hour.precipitationChancePercent,
        WeatherMetric.humidity => hour.humidityPercent,
        WeatherMetric.visibility => hour.visibilityKm,
      };

  /// Bars for an amount counted from zero, a curve for a level.
  ///
  /// Rain and UV are quantities an hour either has or does not, and a line
  /// sloping between two of them draws readings Apple never reported.
  static bool isBars(WeatherMetric metric) => switch (metric) {
    WeatherMetric.precipitation || WeatherMetric.uvIndex => true,
    WeatherMetric.conditions ||
    WeatherMetric.wind ||
    WeatherMetric.humidity ||
    WeatherMetric.visibility => false,
  };

  /// The day's readings as runs of consecutive hours, split wherever Apple
  /// had no value.
  ///
  /// Runs rather than one series: `fl_chart` takes no nulls, so a gap left in
  /// would be drawn as a straight line between the hours either side of it —
  /// a reading invented to cover a missing one.
  static List<List<FlSpot>> segments(
    WeatherMetric metric,
    List<WeatherHourly> hours,
  ) {
    final List<List<FlSpot>> runs = <List<FlSpot>>[];
    List<FlSpot> run = <FlSpot>[];

    for (final (int index, WeatherHourly hour) in hours.indexed) {
      final double? value = number(metric, hour);

      if (value == null) {
        if (run.isNotEmpty) runs.add(run);
        run = <FlSpot>[];
        continue;
      }

      run.add(FlSpot(index.toDouble(), value));
    }

    if (run.isNotEmpty) runs.add(run);

    return runs;
  }

  /// The y range the day is drawn against, from the values it actually has.
  ///
  /// Percentages are pinned to 0–100 and UV to its own scale: auto-scaling a
  /// bounded reading turns a three-point wiggle into a mountain, and this is
  /// an app whose users make decisions off the shape.
  static (double min, double max) range(
    WeatherMetric metric,
    Iterable<double> values,
  ) => switch (metric) {
    WeatherMetric.precipitation || WeatherMetric.humidity => (0, 100),
    WeatherMetric.uvIndex => (
      0,
      max(uvScaleTop, ChartAxisUtils.maxBound(values)),
    ),
    // Calm IS zero and says so; headroom underneath it would say nothing.
    WeatherMetric.wind => (0, ChartAxisUtils.maxBound(values)),
    // Levels around a baseline — a 20° day must not start its axis at 0.
    WeatherMetric.conditions || WeatherMetric.visibility => (
      ChartAxisUtils.minBound(values),
      ChartAxisUtils.maxBound(values),
    ),
  };
}

/// The closed metric picker: the current reading's glyph and a chevron, and
/// nothing else.
///
/// **Icon-only on purpose.** It shares a row with the day summary, and a
/// spelled-out label ("Chance of rain", "Điều kiện") took enough of that row
/// to squeeze the summary — the sheet it opens names every option in full, so
/// the closed state does not have to.
///
/// The sheet is `showSdFilterSheetV2` inlined rather than wrapped: a widget
/// that only forwards to the generic presenter is dead weight (CLAUDE.md
/// § Bottom sheets).
class _MetricPicker extends ConsumerWidget {
  const _MetricPicker({required this.metric});

  final WeatherMetric metric;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final WeatherMetric? picked = await showSdFilterSheetV2<WeatherMetric>(
      context,
      title: l10n.weatherMetricSheetTitle,
      options: WeatherMetric.values,
      selected: metric,
      labelBuilder: (WeatherMetric value) =>
          WeatherMetricUtils.label(l10n, value),
    );

    if (picked == null) return;

    ref.read(weatherMetricProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return Semantics(
      button: true,
      // Icon-only, so the control says nothing to VoiceOver on its own — the
      // reading it is showing is the whole label.
      label: WeatherMetricUtils.label(l10n, metric),
      child: SdPressableScaleV2(
        onTap: () => _open(context, ref),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SdSpacingConstant.w8,
            vertical: SdSpacingConstant.h8,
          ),
          decoration: BoxDecoration(
            color: context.sdTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SdIconV2(
                icon: WeatherMetricUtils.glyph(metric),
                size: SdSpacingConstant.r20,
                color: context.colorScheme.primary,
              ),
              // The chevron is what says this opens something; without it an
              // icon on a tinted pill reads as a status, not a control.
              SdIconV2(
                icon: Icons.expand_more,
                size: SdSpacingConstant.r18,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picked day's hours — iOS Weather's own row, with the dropdown deciding
/// what the numbers under the glyphs mean, and the chart under them drawn from
/// those same numbers.
///
/// **One scroll region, not two.** The cells and the chart share a single
/// `SingleChildScrollView` of a stated width, so hour 14 is at the same x in
/// both however far the user has scrolled. Two scroll views side by side would
/// need their offsets kept in sync, which is a thing to get wrong every frame.
///
/// Not lazy, and that is fine: a day is at most 24 cells.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.hours, required this.metric});

  final List<WeatherHourly> hours;
  final WeatherMetric metric;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();

    if (hours.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _MetricCell.width * hours.length,
        child: Column(
          // Stretch, not optional: the chart states only its height, and a
          // loose width constraint would let it shrink off the cells it is
          // drawn to line up with.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final (int index, WeatherHourly hour) in hours.indexed)
                  _MetricCell(
                    hour: hour,
                    metric: metric,
                    // Only the first hour of the current day is "Now"; on any
                    // other day it is just that day's first hour.
                    isNow:
                        index == 0 && DateTimeUtils.isSameDay(hour.time, now),
                  ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _MetricChart(hours: hours, metric: metric),
          ],
        ),
      ),
    );
  }
}

/// One hour: when, the glyph, the reading.
class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.hour,
    required this.metric,
    required this.isNow,
  });

  final WeatherHourly hour;
  final WeatherMetric metric;
  final bool isNow;

  /// Stated outright: a horizontal scroll view gives its child unbounded
  /// space, so nothing else here would size a cell.
  static double get height =>
      SdSpacingConstant.h16 +
      SdSpacingConstant.h8 +
      SdSpacingConstant.r24 +
      SdSpacingConstant.h8 +
      SdSpacingConstant.h20;

  /// **Fixed, and that is what makes the chart line up.** The chart below
  /// spans `width * hours.length` and maps hour i to the centre of cell i —
  /// an intrinsic width plus a separator would put every column somewhere the
  /// chart cannot compute.
  static double get width => SdSpacingConstant.w56;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            isNow
                ? l10n.weatherNow
                : DateFormat.j().format(hour.time.toLocal()),
            style: AppTextStyle.bodySmall.secondary,
            maxLines: 1,
          ),
          SdIconV2(
            icon: WeatherMetricUtils.icon(metric, hour),
            size: SdSpacingConstant.r24,
            color: AppColors.primary,
          ),
          Text(
            // An em dash, not a blank: an hour Apple had no value for should
            // say so, and an empty slot under a glyph reads as a render bug.
            WeatherMetricUtils.value(l10n, metric, hour) ?? '—',
            style: AppTextStyle.bodyMedium,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
