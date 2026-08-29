part of 'weather_card.dart';

/// The readings, in the order both the card and the sheet list them.
List<_Metric> _metrics(AppLocalizations l10n, WeatherCardData data) {
  return <_Metric>[
    if (data.pressureHpa case final double value)
      _Metric(
        icon: AppIconConstant.pressure,
        label: l10n.weatherDetailPressure,
        // One decimal, unlike every other reading here: a migraine-relevant move is a few hPa, so rounding to whole units hides half of it.
        value: l10n.weatherPressureValue(value.toStringAsFixed(1)),
      ),
    if (data.pressureDelta24hHpa case final double value)
      _Metric(
        icon: AppIconConstant.correlation,
        label: l10n.weatherDetailPressureDelta,
        // Signed, always: "+3" and "-3" are opposite answers, and a bare 3 is neither of them.
        value: l10n.weatherPressureValue(SignedNumberUtils.format(value)),
      ),
    if (data.precipitationChancePercent case final double value)
      _Metric(
        icon: AppIconConstant.precipitation,
        label: l10n.weatherDetailPrecipitation,
        value: l10n.weatherPercent(value.round()),
      ),
    // - fifth, so the card keeps the four readings above this one.
    if (data.precipitationAmountMm case final double value)
      _Metric(
        icon: AppIconConstant.rainfall,
        label: l10n.weatherDetailPrecipitationAmount,
        // One decimal, like pressure and unlike the rest: a day of drizzle is 0.4mm, and rounded to whole millimetres it reads as no rain at all.
        value: l10n.weatherMillimetreValue(value.toStringAsFixed(1)),
      ),
    if (data.humidityPercent case final double value)
      _Metric(
        icon: AppIconConstant.humidity,
        label: l10n.weatherDetailHumidity,
        value: l10n.weatherPercent(value.round()),
      ),

    if (data.windSpeedKph case final double value)
      _Metric(
        icon: AppIconConstant.weatherWindy,
        label: l10n.weatherDetailWind,
        value: l10n.weatherWindValue(value.round()),
      ),
    if (data.uvIndex case final double value)
      _Metric(
        icon: AppIconConstant.weatherClear,
        label: l10n.weatherDetailUv,
        value: l10n.weatherUvValue(value.round()),
      ),
    // Already kilometres off the wire, and rounded: a city block's difference in visibility is not worth a decimal place.
    if (data.visibilityKm case final double value)
      _Metric(
        icon: AppIconConstant.visibility,
        label: l10n.weatherDetailVisibility,
        value: l10n.weatherVisibilityValue(value.round()),
      ),

    if (data.sunrise case final DateTime value)
      _Metric(
        icon: AppIconConstant.daylight,
        label: l10n.weatherDetailSunrise,
        value: DateFormat.jm(l10n.localeName).format(value.toLocal()),
      ),
    if (data.sunset case final DateTime value)
      _Metric(
        icon: AppIconConstant.weatherClearNight,
        label: l10n.weatherDetailSunset,
        value: DateFormat.jm(l10n.localeName).format(value.toLocal()),
      ),
  ];
}

/// One reading, already localized and ready to draw.
@immutable
class _Metric {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// The card's compact readings: glyph over number, sharing one tray.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});

  final List<_Metric> metrics;

  static const int maxOnCard = 4;

  /// Read by the loading skeleton too, so the placeholder reserves the tray's height rather than a guess at it.
  static double get height =>
      SdSpacingConstant.h8 * 2 +
      SdSpacingConstant.r18 +
      SdSpacingConstant.h4 +
      SdSpacingConstant.h16;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        // A step up from the card, like everything else that sits on one — and opaque, so it reads the same at both ends of the gradient.
        color: context.sdTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w12,
          vertical: SdSpacingConstant.h8,
        ),
        child: Row(
          children: <Widget>[
            for (final _Metric metric in metrics.take(maxOnCard))
              Expanded(child: _MetricGlance(metric: metric)),
          ],
        ),
      ),
    );
  }
}

/// One compact reading. Its name is on it for VoiceOver, which cannot read a glyph — the label is dropped from the drawing, never from the semantics.
class _MetricGlance extends StatelessWidget {
  const _MetricGlance({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: metric.label,
      value: metric.value,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdIconV2(
            icon: metric.icon,
            size: AppIconSize.row,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: SdSpacingConstant.h4),
          // Fitted rather than ellipsed: a quarter of the card is tight for "12 km/h" at some text sizes, and a reading cut to "12 k…" is worse than the same.
          SdFittedTextV2(
            metric.value,
            style: AppTextStyle.bodySmall.w600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The sheet's readings: every one of them, named, two to a row.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  /// One gap for both axes, so the grid reads as a grid rather than as rows that happen to be near each other.
  static double get gap => SdSpacingConstant.w8;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        for (int i = 0; i < metrics.length; i += 2) ...<Widget>[
          if (i > 0) SizedBox(height: gap),
          // IntrinsicHeight is not optional.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: _MetricCell(metric: metrics[i])),
                SizedBox(width: gap),
                Expanded(
                  child: i + 1 < metrics.length
                      ? _MetricCell(metric: metrics[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One named cell: the glyph and the name on top, the reading under them.
class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w8,
        vertical: SdSpacingConstant.h8,
      ),
      decoration: BoxDecoration(
        // A step up from the sheet, like everything else that sits on one.
        color: context.sdTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV2(
                icon: metric.icon,
                size: AppIconSize.inline,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: SdSpacingConstant.w4),
              Expanded(
                child: Text(
                  metric.label,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            style: AppTextStyle.bodyMedium.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
