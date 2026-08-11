part of 'weather_card.dart';

/// The days ahead, one row each.
class _DailyList extends StatelessWidget {
  const _DailyList({required this.days});

  final List<WeatherDaily> days;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (days.isEmpty) {
      return Text(
        l10n.weatherUnavailable,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return Column(
      children: <Widget>[
        // Between rows only — a rule above the first would sit on the card's
        // own edge.
        for (final (int index, WeatherDaily day) in days.indexed) ...<Widget>[
          if (index > 0) const SdDividerV2(),
          _DayRow(day: day, isToday: index == 0),
        ],
      ],
    );
  }
}

/// One day: the weekday, the glyph, then the low and the high.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.isToday});

  final WeatherDaily day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? low = WeatherConditionUtils.temperature(
      l10n,
      day.temperatureMinCelsius,
    );
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      day.temperatureMaxCelsius,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              isToday
                  ? l10n.weatherNow
                  : DateFormat.E().format(day.date.toLocal()),
              style: AppTextStyle.bodyMedium,
            ),
          ),
          SdIconV2(
            icon: WeatherConditionUtils.icon(day.condition),
            size: SdSpacingConstant.r20,
            color: AppColors.primary,
          ),
          SizedBox(width: SdSpacingConstant.w16),
          // The low muted and the high not: the pair reads as a range, and
          // the high is the number people look for.
          Text(low ?? '', style: AppTextStyle.bodyMedium.secondary),
          SizedBox(width: SdSpacingConstant.w8),
          Text(high ?? '', style: AppTextStyle.bodyMedium),
        ],
      ),
    );
  }
}
