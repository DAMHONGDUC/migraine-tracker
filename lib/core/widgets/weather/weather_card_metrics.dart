part of 'weather_card.dart';

/// The readings under the headline, in the order the card lists them.
///
/// **Only what actually has a value.** A reading Apple never sent, or a
/// snapshot field that was never stored, is left out rather than printed as
/// a dash — so the grid is four cells on one surface and three on another,
/// and neither reads as broken.
///
/// Pressure leads where it is present: it is the reading this app exists for,
/// and the 24-hour change beside it is what an attack is read against.
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

/// The readings two to a row.
///
/// **Rows of `Expanded`, never a `GridView` with a `childAspectRatio`.** A
/// ratio ties a cell's height to whatever width is left over, which is how
/// the previous weather card's details grid came to overflow (see the
/// dashboard's own rules); this sizes to content and cannot.
///
/// **An odd count leaves the last cell at half width** rather than stretching
/// it across the row: a cell that is suddenly twice as wide as the five above
/// it reads as a different kind of thing.
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
          // ListView that axis is unbounded — which asserts "BoxConstraints
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

/// One cell: the glyph and the name on top, the reading under them.
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
        // A step up from the card, like everything else that sits on one.
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
