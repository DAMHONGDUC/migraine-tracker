part of 'weather_card.dart';

/// The hours ahead, scrolling sideways like iOS Weather's own strip.
class _HourlyStrip extends StatelessWidget {
  const _HourlyStrip({required this.hours});

  final List<WeatherHourly> hours;

  /// Two days of it. Longer than the pressure chart's window would be a strip
  /// nobody scrolls to the end of.
  static const int _maxHours = 48;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<WeatherHourly> shown = hours.take(_maxHours).toList();

    if (shown.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return SizedBox(
      height: SdSpacingConstant.h96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length,
        separatorBuilder: (_, _) => SizedBox(width: SdSpacingConstant.w16),
        itemBuilder: (BuildContext context, int index) =>
            _HourCell(hour: shown[index], isFirst: index == 0),
      ),
    );
  }
}

/// One hour: when, what, and how warm.
class _HourCell extends StatelessWidget {
  const _HourCell({required this.hour, required this.isFirst});

  final WeatherHourly hour;

  /// The first cell is the current hour and says "Now" instead of a clock
  /// time — the strip starts at the present, so a time there reads as a
  /// forecast for something already happening.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? temperature = WeatherConditionUtils.temperature(
      l10n,
      hour.temperatureCelsius,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          isFirst
              ? l10n.weatherNow
              : DateFormat.j().format(hour.time.toLocal()),
          style: AppTextStyle.bodySmall.secondary,
        ),
        SdIconV2(
          icon: WeatherConditionUtils.icon(hour.condition),
          size: SdSpacingConstant.r24,
          color: AppColors.primary,
        ),
        Text(temperature ?? '', style: AppTextStyle.bodyMedium),
      ],
    );
  }
}
