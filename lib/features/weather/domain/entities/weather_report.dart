import 'package:meta/meta.dart';

import '../../../../core/utils/date_time_utils.dart';

/// Everything the weather card draws: conditions now, the hours ahead, and
/// the days after that.
///
/// **Every field below the top level is nullable, and that is the contract.**
/// WeatherKit omits what it has no data for at a location, so the card
/// renders what arrived rather than asserting a shape — the field-level twin
/// of hard rule 4's "weather is best-effort".
@immutable
class WeatherReport {
  const WeatherReport({
    required this.hours,
    required this.days,
    this.current,
  });

  final WeatherConditions? current;

  /// Ascending by time, UTC.
  final List<WeatherHourly> hours;
  final List<WeatherDaily> days;

  /// Whether there is anything at all worth drawing.
  bool get isEmpty => current == null && hours.isEmpty && days.isEmpty;

  /// How many days the forecast offers, today counted as the first.
  ///
  /// **Ten, which is also Apple's ceiling** (owner's call). `forecastDaily`
  /// runs ten days out and `forecastHourly` 240 hours, so this is the whole
  /// of what WeatherKit knows rather than a number picked to look round —
  /// asking for an eleventh would return nothing to draw.
  static const int forecastDayCount = 10;

  /// The days the sheet's rainfall forecast lists, today first.
  List<WeatherDaily> get forecastDays =>
      days.take(forecastDayCount).toList();

  /// The hours falling on [day], by local calendar date.
  ///
  /// Local and not UTC: the user picks "Wednesday" from a strip drawn in
  /// their own timezone, so the hours under it have to be their Wednesday.
  List<WeatherHourly> hoursOn(DateTime day) => hours
      .where((WeatherHourly hour) => DateTimeUtils.isSameDay(hour.time, day))
      .toList();
}

/// Conditions at one instant — what the top of the card reads.
@immutable
class WeatherConditions {
  const WeatherConditions({
    required this.time,
    this.pressureHpa,
    this.pressureTrend,
    this.temperatureCelsius,
    this.apparentTemperatureCelsius,
    this.humidityPercent,
    this.uvIndex,
    this.condition,
    this.windSpeedKph,
    this.cloudCoverPercent,
    this.visibilityKm,
    this.daylight,
  });

  final DateTime time;
  final double? pressureHpa;
  final PressureTrend? pressureTrend;
  final double? temperatureCelsius;
  final double? apparentTemperatureCelsius;
  final double? humidityPercent;
  final double? uvIndex;
  final WeatherCondition? condition;
  final double? windSpeedKph;
  final double? cloudCoverPercent;
  final double? visibilityKm;

  /// Whether the sun is up — what picks the day or night glyph.
  final bool? daylight;
}

/// One hour of the forecast.
@immutable
class WeatherHourly {
  const WeatherHourly({
    required this.time,
    required this.pressureHpa,
    this.temperatureCelsius,
    this.apparentTemperatureCelsius,
    this.humidityPercent,
    this.uvIndex,
    this.condition,
    this.precipitationChancePercent,
    this.precipitationAmountMm,
    this.windSpeedKph,
    this.cloudCoverPercent,
    this.visibilityKm,
  });

  /// UTC, hour resolution.
  final DateTime time;

  /// The one field that is never null: an hour without it is dropped by the
  /// backend, because pressure is what the alert maths runs on.
  final double pressureHpa;

  final double? temperatureCelsius;
  final double? apparentTemperatureCelsius;
  final double? humidityPercent;
  final double? uvIndex;
  final WeatherCondition? condition;
  final double? precipitationChancePercent;

  /// Millimetres in the hour — rain and melted snow together, as Apple sends
  /// it. Separate from the chance: a 90% chance of 0.2mm and a 30% chance of
  /// 20mm are different days, and only one of them changes plans.
  final double? precipitationAmountMm;

  final double? windSpeedKph;
  final double? cloudCoverPercent;
  final double? visibilityKm;
}

/// One day of the forecast.
@immutable
class WeatherDaily {
  const WeatherDaily({
    required this.date,
    this.condition,
    this.temperatureMaxCelsius,
    this.temperatureMinCelsius,
    this.precipitationChancePercent,
    this.precipitationAmountMm,
    this.uvIndexMax,
    this.sunrise,
    this.sunset,
  });

  /// The day's start, UTC.
  final DateTime date;
  final WeatherCondition? condition;
  final double? temperatureMaxCelsius;
  final double? temperatureMinCelsius;
  final double? precipitationChancePercent;

  /// Millimetres over the whole day.
  final double? precipitationAmountMm;

  final double? uvIndexMax;
  final DateTime? sunrise;
  final DateTime? sunset;
}

/// Which way the pressure is going, as Apple reports it.
///
/// Its own enum rather than the raw string: the card reads a direction, and
/// an unrecognised word from a future WeatherKit version becomes null instead
/// of reaching the UI as text nobody translated.
enum PressureTrend {
  rising,
  falling,
  steady;

  static PressureTrend? fromCode(String? code) => switch (code?.toLowerCase()) {
    'rising' => PressureTrend.rising,
    'falling' => PressureTrend.falling,
    'steady' => PressureTrend.steady,
    _ => null,
  };
}

/// The weather in one word, reduced from WeatherKit's ~50 condition codes to
/// the handful the card can draw a glyph for.
///
/// Deliberately coarse. Apple distinguishes `Drizzle` from `HeavyRain` from
/// `Rain`; this app is a migraine tracker, and the extra precision would buy
/// nothing but more strings to translate into both locales (hard rule 6).
enum WeatherCondition {
  clear,
  cloudy,
  partlyCloudy,
  rain,
  snow,
  sleet,
  thunderstorms,
  fog,
  windy,
  hazy;

  /// Maps Apple's code, or null for one this build has never heard of — a
  /// new code must degrade to "no glyph", never to a wrong one.
  static WeatherCondition? fromCode(String? code) {
    if (code == null) return null;

    final String value = code.toLowerCase();

    if (value.contains('thunder')) return WeatherCondition.thunderstorms;
    if (value.contains('sleet') || value.contains('freezing')) {
      return WeatherCondition.sleet;
    }
    if (value.contains('snow') || value.contains('flurries')) {
      return WeatherCondition.snow;
    }
    if (value.contains('rain') || value.contains('drizzle')) {
      return WeatherCondition.rain;
    }
    if (value.contains('fog')) return WeatherCondition.fog;
    if (value.contains('haze') || value.contains('smoke')) {
      return WeatherCondition.hazy;
    }
    if (value.contains('wind') || value.contains('breezy')) {
      return WeatherCondition.windy;
    }
    if (value.contains('partlycloudy') || value.contains('mostlyclear')) {
      return WeatherCondition.partlyCloudy;
    }
    if (value.contains('cloudy')) return WeatherCondition.cloudy;
    if (value.contains('clear') || value.contains('sunny')) {
      return WeatherCondition.clear;
    }

    return null;
  }
}
