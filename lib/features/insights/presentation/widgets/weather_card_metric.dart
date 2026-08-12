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

/// The picked day's hours, scrolling sideways — iOS Weather's own row, with
/// the dropdown deciding what the numbers under the glyphs mean.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.hours, required this.metric});

  final List<WeatherHourly> hours;
  final WeatherMetric metric;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (hours.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return SizedBox(
      height: _MetricCell.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        separatorBuilder: (_, _) => SizedBox(width: SdSpacingConstant.w16),
        itemBuilder: (BuildContext context, int index) => _MetricCell(
          hour: hours[index],
          metric: metric,
          isNow: index == 0 && _isToday(hours[index].time),
        ),
      ),
    );
  }

  /// Only the first hour of the current day is "Now"; on any other day the
  /// first cell is just that day's first hour.
  bool _isToday(DateTime time) {
    final DateTime now = DateTime.now();
    final DateTime local = time.toLocal();

    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
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

  /// Stated outright: a horizontal `ListView` gives its children unbounded
  /// height, so nothing else here would size them.
  static double get height =>
      SdSpacingConstant.h16 +
      SdSpacingConstant.h8 +
      SdSpacingConstant.r24 +
      SdSpacingConstant.h8 +
      SdSpacingConstant.h20;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          isNow ? l10n.weatherNow : DateFormat.j().format(hour.time.toLocal()),
          style: AppTextStyle.bodySmall.secondary,
          maxLines: 1,
        ),
        SdIconV2(
          icon: WeatherMetricUtils.icon(metric, hour),
          size: SdSpacingConstant.r24,
          color: AppColors.primary,
        ),
        Text(
          WeatherMetricUtils.value(l10n, metric, hour) ?? '',
          style: AppTextStyle.bodyMedium,
          maxLines: 1,
        ),
      ],
    );
  }
}
