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
        night ? Icons.nightlight_outlined : Icons.wb_sunny_outlined,
      WeatherCondition.partlyCloudy =>
        night ? Icons.nights_stay_outlined : Icons.wb_cloudy_outlined,
      WeatherCondition.cloudy => Icons.cloud_outlined,
      WeatherCondition.rain => Icons.water_drop_outlined,
      WeatherCondition.snow => Icons.ac_unit,
      WeatherCondition.sleet => Icons.grain,
      WeatherCondition.thunderstorms => Icons.thunderstorm_outlined,
      WeatherCondition.fog => Icons.foggy,
      WeatherCondition.windy => Icons.air,
      WeatherCondition.hazy => Icons.blur_on,
      // A code this build has never heard of, or none at all.
      null => Icons.help_outline,
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

  static String? trend(AppLocalizations l10n, PressureTrend? trend) =>
      switch (trend) {
        PressureTrend.rising => l10n.weatherTrendRising,
        PressureTrend.falling => l10n.weatherTrendFalling,
        PressureTrend.steady => l10n.weatherTrendSteady,
        null => null,
      };

  /// A temperature as the card says it: rounded, degree sign, no unit.
  ///
  /// Null in means null out, so a caller can pass a field straight through
  /// and decide what an absent reading looks like.
  static String? temperature(AppLocalizations l10n, double? celsius) =>
      celsius == null ? null : l10n.weatherTemperature(celsius.round());
}
