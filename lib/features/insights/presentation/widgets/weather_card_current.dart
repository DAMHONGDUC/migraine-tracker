part of 'weather_card.dart';

/// Conditions right now: the glyph, the temperature, and what it feels like.
class _Current extends StatelessWidget {
  const _Current({required this.current});

  final WeatherConditions? current;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherConditions? now = current;

    // Apple served hours but no `currentWeather` for this location. The rest
    // of the card still has something to draw, so this half just steps aside.
    if (now == null) return const SizedBox.shrink();

    final String? temperature = WeatherConditionUtils.temperature(
      l10n,
      now.temperatureCelsius,
    );
    final String? feelsLike = WeatherConditionUtils.temperature(
      l10n,
      now.apparentTemperatureCelsius,
    );
    final String? condition = WeatherConditionUtils.label(l10n, now.condition);

    return Row(
      children: <Widget>[
        SdIconV2(
          icon: WeatherConditionUtils.icon(
            now.condition,
            daylight: now.daylight,
          ),
          size: SdSpacingConstant.r36,
          color: AppColors.primary,
        ),
        SizedBox(width: SdSpacingConstant.w16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (temperature != null)
                Text(temperature, style: AppTextStyle.headlineMedium),
              if (condition != null)
                Text(condition, style: AppTextStyle.bodyMedium.secondary),
              if (feelsLike != null)
                Text(
                  l10n.weatherFeelsLike(feelsLike),
                  style: AppTextStyle.bodySmall.secondary,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
