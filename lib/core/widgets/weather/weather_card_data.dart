part of 'weather_card.dart';

/// Everything [WeatherCard] can draw, already reduced to the fields it draws.
@immutable
class WeatherCardData {
  const WeatherCardData({
    this.condition,
    this.daylight,
    this.temperatureCelsius,
    this.apparentTemperatureCelsius,
    this.pressureHpa,
    this.pressureDelta24hHpa,
    this.humidityPercent,
    this.windSpeedKph,
    this.uvIndex,
    this.visibilityKm,
    this.precipitationChancePercent,
    this.precipitationAmountMm,
    this.sunrise,
    this.sunset,
    this.forecast,
    this.days = const <WeatherDaily>[],
    this.hours = const <WeatherHourly>[],
  });

  /// The conditions the user is standing in.
  factory WeatherCardData.of(WeatherReport report) {
    final WeatherConditions? now = report.current;
    final List<WeatherDaily> upcoming = report.forecastDays;

    return WeatherCardData(
      condition: now?.condition,
      daylight: now?.daylight,
      temperatureCelsius: now?.temperatureCelsius,
      apparentTemperatureCelsius: now?.apparentTemperatureCelsius,
      humidityPercent: now?.humidityPercent,
      windSpeedKph: now?.windSpeedKph,
      uvIndex: now?.uvIndex,
      visibilityKm: now?.visibilityKm,
      pressureHpa: now?.pressureHpa,
      // The coming 24 hours, which is the window the drop alert itself runs on — the app's one definition of "a 24h change" in the future.
      pressureDelta24hHpa: _pressureChange(report.hours.take(_dayHours + 1)),
      // What the current block never carries: how likely rain is, how much falls, and the sun's hours are facts about a day, not an instant.
      precipitationChancePercent: upcoming.isEmpty
          ? null
          : upcoming.first.precipitationChancePercent,
      precipitationAmountMm: upcoming.isEmpty
          ? null
          : upcoming.first.precipitationAmountMm,
      sunrise: upcoming.isEmpty ? null : upcoming.first.sunrise,
      sunset: upcoming.isEmpty ? null : upcoming.first.sunset,
      forecast: upcoming.isEmpty ? null : upcoming.first,
      days: upcoming,
      hours: report.hours,
    );
  }

  /// The conditions an attack was logged in.
  factory WeatherCardData.ofSnapshot(WeatherSnapshot snapshot) =>
      WeatherCardData(
        temperatureCelsius: snapshot.temperatureCelsius,
        pressureHpa: snapshot.pressureHpa,
        pressureDelta24hHpa: snapshot.pressureDelta24hHpa,
        humidityPercent: snapshot.humidityPercent,
      );

  final WeatherCondition? condition;

  /// Whether the sun is up — what picks the day or night glyph.
  final bool? daylight;

  final double? temperatureCelsius;
  final double? apparentTemperatureCelsius;
  final double? pressureHpa;
  final double? pressureDelta24hHpa;
  final double? humidityPercent;
  final double? windSpeedKph;
  final double? uvIndex;
  final double? visibilityKm;
  final double? precipitationChancePercent;

  /// How much rain the day is expected to bring, in millimetres.
  final double? precipitationAmountMm;

  /// Today's, in UTC like everything else off the wire.
  final DateTime? sunrise;
  final DateTime? sunset;

  /// The days ahead, today first — `WeatherReport.forecastDays`, so at most `WeatherReport.forecastDayCount` (10) of them.
  final List<WeatherDaily> days;

  /// The day this data describes — today for a live report, or whichever day [dayAt] was asked for.
  final WeatherDaily? forecast;

  /// Every hour the report carried, across the whole week. [dayAt] slices it; nothing draws it directly.
  final List<WeatherHourly> hours;

  /// The same readings, for another day of [days].
  WeatherCardData dayAt(int index) {
    if (index <= 0 || index >= days.length) return this;

    final WeatherDaily day = days[index];
    final List<WeatherHourly> onDay = hours
        .where(
          (WeatherHourly hour) => DateTimeUtils.isSameDay(hour.time, day.date),
        )
        .toList();

    return WeatherCardData(
      condition: day.condition,
      humidityPercent: _mean(
        onDay.map((WeatherHourly hour) => hour.humidityPercent),
      ),
      windSpeedKph: _mean(onDay.map((WeatherHourly hour) => hour.windSpeedKph)),
      uvIndex: day.uvIndexMax,
      visibilityKm: _mean(onDay.map((WeatherHourly hour) => hour.visibilityKm)),
      pressureHpa: _mean(onDay.map((WeatherHourly hour) => hour.pressureHpa)),
      // First hour to last, which for a whole day IS the 24-hour change.
      pressureDelta24hHpa: _pressureChange(onDay),
      precipitationChancePercent: day.precipitationChancePercent,
      precipitationAmountMm: day.precipitationAmountMm,
      sunrise: day.sunrise,
      sunset: day.sunset,
      forecast: day,
      days: days,
      hours: hours,
    );
  }

  /// A day's worth of hourly readings.
  static const int _dayHours = 24;

  /// How far the pressure moves across [hours], first reading to last.
  static double? _pressureChange(Iterable<WeatherHourly> hours) {
    final List<WeatherHourly> ordered = hours.toList();

    if (ordered.length < 2) return null;

    return ordered.last.pressureHpa - ordered.first.pressureHpa;
  }

  /// The mean of the values that exist, or null when none do — an hour Apple had no reading for must not be counted as a zero.
  static double? _mean(Iterable<double?> values) {
    final List<double> present = values.nonNulls.toList();

    if (present.isEmpty) return null;

    return present.reduce((double a, double b) => a + b) / present.length;
  }

  /// Whether there is anything at all worth drawing.
  bool get isEmpty =>
      condition == null &&
      temperatureCelsius == null &&
      apparentTemperatureCelsius == null &&
      pressureHpa == null &&
      pressureDelta24hHpa == null &&
      humidityPercent == null &&
      windSpeedKph == null &&
      uvIndex == null &&
      visibilityKm == null &&
      precipitationChancePercent == null &&
      precipitationAmountMm == null &&
      sunrise == null &&
      sunset == null &&
      days.isEmpty;
}
