part of 'weather_card.dart';

/// Turns a [WeatherCondition] into the glyph and the word the card shows.
///
/// Here rather than in `domain/`, because an `IconData` is a Flutter type and
/// `domain/` stays pure Dart.
final class WeatherConditionUtils {
  /// The night variant only differs where the sky itself does — rain looks
  /// the same at midnight, a clear sky does not.
  static IconData icon(WeatherCondition? condition, {bool? daylight}) {
    final bool night = daylight == false;

    return switch (condition) {
      WeatherCondition.clear =>
        night ? AppIconConstant.weatherClearNight : AppIconConstant.weatherClear,
      WeatherCondition.partlyCloudy =>
        night ? AppIconConstant.weatherCloudyNight : AppIconConstant.weatherPartlyCloudy,
      WeatherCondition.cloudy => AppIconConstant.weatherCloudy,
      // A cloud shedding drops, not `water_drop_outlined` — a bare droplet is
      // the humidity glyph, so a rainy hour read as a humidity readout.
      WeatherCondition.rain => AppIconConstant.weatherRain,
      WeatherCondition.snow => AppIconConstant.weatherSnow,
      WeatherCondition.sleet => AppIconConstant.weatherSleet,
      WeatherCondition.thunderstorms => AppIconConstant.weatherThunderstorms,
      WeatherCondition.fog => AppIconConstant.weatherFog,
      WeatherCondition.windy => AppIconConstant.weatherWindy,
      WeatherCondition.hazy => AppIconConstant.weatherHazy,
      // A code this build has never heard of, or none at all.
      null => AppIconConstant.weatherUnknown,
    };
  }

  static String? label(AppLocalizations l10n, WeatherCondition? condition) =>
      switch (condition) {
        WeatherCondition.clear => l10n.weatherConditionClear,
        WeatherCondition.cloudy => l10n.weatherConditionCloudy,
        WeatherCondition.partlyCloudy => l10n.weatherConditionPartlyCloudy,
        WeatherCondition.rain => l10n.weatherConditionRain,
        WeatherCondition.snow => l10n.weatherConditionSnow,
        WeatherCondition.sleet => l10n.weatherConditionSleet,
        WeatherCondition.thunderstorms => l10n.weatherConditionThunderstorms,
        WeatherCondition.fog => l10n.weatherConditionFog,
        WeatherCondition.windy => l10n.weatherConditionWindy,
        WeatherCondition.hazy => l10n.weatherConditionHazy,
        null => null,
      };

  /// A temperature as the card says it: rounded, degree sign, no unit.
  ///
  /// Null in means null out, so a caller can pass a field straight through
  /// and decide what an absent reading looks like.
  static String? temperature(AppLocalizations l10n, double? celsius) =>
      celsius == null ? null : l10n.weatherTemperature(celsius.round());
}
