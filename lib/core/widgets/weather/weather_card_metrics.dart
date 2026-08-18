part of 'weather_card.dart';

/// The readings, in the order both the card and the sheet list them.
///
/// **Only what actually has a value.** A reading Apple never sent, or a
/// snapshot field that was never stored, is left out rather than printed as
/// a dash — so it is four readings on one surface and three on another, and
/// neither reads as broken.
///
/// **The order is the gate between the two surfaces.** The card draws the
/// first `_MetricStrip.maxOnCard` (4) and the sheet draws them all, so what
/// leads this list is what a glance gets: the four free readings of the sky.
/// Pressure, the chance of rain and the sun's hours come after, and reach the
/// sheet alone — pressure because the dashboard's Today section already
/// prints it a card away, and the other three because they are worth knowing
/// and not worth a quarter of the card.
///
/// A stored snapshot has only three readings in total, so its card shows all
/// of them and the order decides nothing.
List<_Metric> _metrics(AppLocalizations l10n, WeatherCardData data) {
  return <_Metric>[
    if (data.pressureHpa case final double value)
      _Metric(
        icon: Icons.compress,
        label: l10n.weatherDetailPressure,
        // One decimal, unlike every other reading here: a migraine-relevant
        // move is a few hPa, so rounding to whole units hides half of it.
        value: l10n.weatherPressureValue(value.toStringAsFixed(1)),
      ),
    if (data.pressureDelta24hHpa case final double value)
      _Metric(
        icon: Icons.timeline,
        label: l10n.weatherDetailPressureDelta,
        // Signed, always: "+3" and "-3" are opposite answers, and a bare 3
        // is neither of them.
        value: l10n.weatherPressureValue(SignedNumberUtils.format(value)),
      ),
    if (data.precipitationChancePercent case final double value)
      _Metric(
        icon: Icons.umbrella_outlined,
        label: l10n.weatherDetailPrecipitation,
        value: l10n.weatherPercent(value.round()),
      ),
    // One decimal, like pressure and unlike the rest: a day of drizzle is
    // 0.4mm, and rounded to whole millimetres it reads as no rain at all.
    if (data.precipitationAmountMm case final double value)
      _Metric(
        icon: Icons.water_outlined,
        label: l10n.weatherDetailPrecipitationAmount,
        value: l10n.weatherMillimetreValue(value.toStringAsFixed(1)),
      ),
    if (data.humidityPercent case final double value)
      _Metric(
        icon: Icons.water_drop_outlined,
        label: l10n.weatherDetailHumidity,
        value: l10n.weatherPercent(value.round()),
      ),
    if (data.windSpeedKph case final double value)
      _Metric(
        icon: Icons.air,
        label: l10n.weatherDetailWind,
        value: l10n.weatherWindValue(value.round()),
      ),
    if (data.uvIndex case final double value)
      _Metric(
        icon: Icons.wb_sunny_outlined,
        label: l10n.weatherDetailUv,
        value: l10n.weatherUvValue(value.round()),
      ),
    // Already kilometres off the wire, and rounded: a city block's difference
    // in visibility is not worth a decimal place.
    if (data.visibilityKm case final double value)
      _Metric(
        icon: Icons.visibility_outlined,
        label: l10n.weatherDetailVisibility,
        value: l10n.weatherVisibilityValue(value.round()),
      ),

    if (data.sunrise case final DateTime value)
      _Metric(
        icon: Icons.wb_twilight,
        label: l10n.weatherDetailSunrise,
        value: DateFormat.jm(l10n.localeName).format(value.toLocal()),
      ),
    if (data.sunset case final DateTime value)
      _Metric(
        icon: Icons.nightlight_outlined,
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
///
/// **No labels, and that is what the arrow is for.** A named grid on the card
/// is what made it the tallest thing on the dashboard; here the glyph stands
/// for the reading and [WeatherDetailSheet] spells every one of them out.
///
/// **One tray, not four chips.** They were bare on the gradient first, which
/// left four small marks floating with nothing holding them together; a chip
/// each was the other try, and its padding ate the width — at a quarter of
/// the card "12 km/h" does not fit inside a chip's own inset. A single
/// rounded surface gives the row an edge, keeps every reading the same
/// quarter wide, and costs the numbers no room at all.
///
/// **At most [maxOnCard] of them.** Four is what fits the design width with
/// a number under each still legible; a fifth would squeeze all five, and the
/// arrow is already the way to the rest.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});

  final List<_Metric> metrics;

  static const int maxOnCard = 4;

  /// Read by the loading skeleton too, so the placeholder reserves the tray's
  /// height rather than a guess at it.
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
        // A step up from the card, like everything else that sits on one —
        // and opaque, so it reads the same at both ends of the gradient.
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

/// One compact reading. Its name is on it for VoiceOver, which cannot read a
/// glyph — the label is dropped from the drawing, never from the semantics.
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
            size: SdSpacingConstant.r18,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: SdSpacingConstant.h4),
          // Fitted rather than ellipsed: a quarter of the card is tight for
          // "12 km/h" at some text sizes, and a reading cut to "12 k…" is
          // worse than the same reading a point smaller.
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
///
/// **Rows of `Expanded`, never a `GridView` with a `childAspectRatio`.** A
/// ratio ties a cell's height to whatever width is left over, which is how
/// the previous weather card's details grid came to overflow (see the
/// dashboard's own rules); this sizes to content and cannot.
///
/// **An odd count leaves the last cell at half width** rather than stretching
/// it across the row: a cell suddenly twice as wide as the ones above it
/// reads as a different kind of thing.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  /// One gap for both axes, so the grid reads as a grid rather than as rows
  /// that happen to be near each other.
  static double get gap => SdSpacingConstant.w8;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        for (int i = 0; i < metrics.length; i += 2) ...<Widget>[
          if (i > 0) SizedBox(height: gap),
          // IntrinsicHeight, and it is not optional: `stretch` tells a Row its
          // children must fill the cross axis, and inside a Column in a
          // scroll view that axis is unbounded — which asserts "BoxConstraints
          // forces an infinite height" on every frame. This bounds the height
          // to the taller cell first, so both come out that height.
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
///
/// The name is capped at one line rather than wrapped, so the two cells of a
/// row are the same height whatever locale they are read in.
class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w12,
        vertical: SdSpacingConstant.h12,
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
                size: SdSpacingConstant.r16,
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
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            metric.value,
            style: AppTextStyle.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
