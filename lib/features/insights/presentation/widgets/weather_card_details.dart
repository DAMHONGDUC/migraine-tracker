part of 'weather_card.dart';

/// Everything that is a reading rather than a forecast: humidity, UV, wind,
/// visibility, pressure, cloud cover, chance of rain.
///
/// Only what actually arrived is drawn — Apple omits fields it has no data
/// for at a location, and a row reading "—" says nothing a missing row does
/// not say more quietly.
class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.current, required this.hours});

  final WeatherConditions? current;
  final List<WeatherHourly> hours;

  /// Two to a row, like the log flow's option grids.
  static const int _columns = 2;

  /// The cell's height, stated outright rather than derived from an aspect
  /// ratio.
  ///
  /// A ratio ties height to width, and the width here is whatever is left of
  /// the screen after the gutter, the card and the column gap — so the cell
  /// was 60pt tall for 64pt of content and every tile overflowed. Summed from
  /// what is actually in one: the padding, the label row, the gap, the value.
  static double get _cellHeight =>
      SdSpacingConstant.h12 * 2 +
      SdSpacingConstant.h20 +
      SdSpacingConstant.h4 +
      SdSpacingConstant.h24;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherConditions? now = current;
    // Chance of rain is hourly only — WeatherKit does not put it on
    // `currentWeather`, so the current hour stands in for "now".
    final WeatherHourly? thisHour = hours.isEmpty ? null : hours.first;
    final List<_Detail> details = <_Detail>[
      if (now?.humidityPercent case final double value)
        _Detail(
          icon: Icons.water_drop_outlined,
          label: l10n.weatherDetailHumidity,
          value: l10n.weatherPercent(value.round()),
        ),
      if (now?.uvIndex case final double value)
        _Detail(
          icon: Icons.wb_sunny_outlined,
          label: l10n.weatherDetailUv,
          value: l10n.weatherUvValue(value.round()),
        ),
      if (now?.windSpeedKph case final double value)
        _Detail(
          icon: Icons.air,
          label: l10n.weatherDetailWind,
          value: l10n.weatherWindValue(value.round()),
        ),
      if (now?.visibilityKm case final double value)
        _Detail(
          icon: Icons.visibility_outlined,
          label: l10n.weatherDetailVisibility,
          value: l10n.weatherVisibilityValue(value.round()),
        ),
      if (now?.pressureHpa case final double value)
        _Detail(
          icon: Icons.compress,
          label: l10n.weatherDetailPressure,
          value: l10n.insightsPressureValue('${value.round()}'),
        ),
      // Its own cell rather than a second line inside the pressure one: a
      // cell that is taller than its neighbours makes the whole grid taller,
      // and every tile then carries the empty line the trend needed.
      if (WeatherConditionUtils.trend(l10n, now?.pressureTrend)
          case final String trend)
        _Detail(
          icon: Icons.trending_down,
          label: l10n.weatherDetailTrend,
          value: trend,
        ),
      if (now?.cloudCoverPercent case final double value)
        _Detail(
          icon: Icons.cloud_outlined,
          label: l10n.weatherDetailCloudCover,
          value: l10n.weatherPercent(value.round()),
        ),
      if (thisHour?.precipitationChancePercent case final double value)
        _Detail(
          icon: Icons.umbrella_outlined,
          label: l10n.weatherDetailPrecipitation,
          value: l10n.weatherPercent(value.round()),
        ),
    ];

    if (details.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return GridView.builder(
      // A scroll view with a null padding helps itself to the ambient
      // MediaQuery inset — the notch would land inside the card.
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        crossAxisSpacing: SdSpacingConstant.w8,
        mainAxisSpacing: SdSpacingConstant.h8,
        mainAxisExtent: _cellHeight,
      ),
      itemBuilder: (BuildContext context, int index) =>
          _DetailCell(detail: details[index]),
    );
  }
}

/// One reading, ready to draw.
///
/// No optional extra line: every cell is the same two rows, which is what
/// lets the grid state one height for all of them.
class _Detail {
  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  /// Both already localized.
  final String label;
  final String value;
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.detail});

  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SdSpacingConstant.w12),
      decoration: BoxDecoration(
        // A step up, like everything else that sits on a card.
        color: context.sdTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV2(
                icon: detail.icon,
                size: SdSpacingConstant.r16,
                color: context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: SdSpacingConstant.w6),
              Expanded(
                child: Text(
                  detail.label,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            detail.value,
            style: AppTextStyle.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
