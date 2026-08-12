part of 'weather_card.dart';

/// The picked day in one line: the glyph, the temperature, the condition.
///
/// [current] is passed only for today, where the live reading is the honest
/// headline. Every other day has no "now", so its high and low are.
class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, required this.current});

  final WeatherDaily? day;
  final WeatherConditions? current;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherConditions? now = current;
    final WeatherDaily? forecast = day;

    // Apple served hours but neither a daily entry nor current conditions.
    // The hourly row below still has something to draw, so this steps aside.
    if (now == null && forecast == null) return const SizedBox.shrink();

    final WeatherCondition? condition = now?.condition ?? forecast?.condition;
    final String? headline = now == null
        ? _range(l10n, forecast)
        : WeatherConditionUtils.temperature(l10n, now.temperatureCelsius);
    final String? caption = now == null
        ? WeatherConditionUtils.label(l10n, condition)
        : _feelsLike(l10n, now, condition);

    return Row(
      children: <Widget>[
        // Smaller glyph and gap than the full-width version this replaced:
        // the dropdown now shares the row, and those pixels are the caption's.
        SdIconV2(
          icon: WeatherConditionUtils.icon(
            condition,
            daylight: now?.daylight,
          ),
          size: SdSpacingConstant.r24,
          color: AppColors.primary,
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (headline != null)
                Text(
                  headline,
                  style: AppTextStyle.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Two lines rather than an ellipsis: the condition and what it
              // feels like are both the point, and a Vietnamese pair of them
              // does not fit one line beside the pill.
              if (caption != null)
                Text(
                  caption,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// "24° / 31°" — low first, the order every forecast states it in.
  String? _range(AppLocalizations l10n, WeatherDaily? forecast) {
    final String? low = WeatherConditionUtils.temperature(
      l10n,
      forecast?.temperatureMinCelsius,
    );
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      forecast?.temperatureMaxCelsius,
    );

    if (low == null && high == null) return null;

    return l10n.weatherRange(low ?? '—', high ?? '—');
  }

  /// The condition word, and what it feels like when Apple says so.
  String? _feelsLike(
    AppLocalizations l10n,
    WeatherConditions now,
    WeatherCondition? condition,
  ) {
    final String? label = WeatherConditionUtils.label(l10n, condition);
    final String? apparent = WeatherConditionUtils.temperature(
      l10n,
      now.apparentTemperatureCelsius,
    );

    if (apparent == null) return label;

    final String feels = l10n.weatherFeelsLike(apparent);

    return label == null ? feels : '$label · $feels';
  }
}
