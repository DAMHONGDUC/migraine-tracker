import 'package:meta/meta.dart';

@immutable
class PressurePoint {
  const PressurePoint({required this.time, required this.pressureHpa});

  /// UTC, hour resolution.
  final DateTime time;
  final double pressureHpa;
}

/// Hourly pressure around now: five days behind, a week of forecast ahead — what the premium forecast chart renders.
@immutable
class PressureForecast {
  const PressureForecast({required this.generatedAt, required this.points});

  /// How far ahead the chart reaches.
  static const int forecastDays = 7;

  /// Hours of already-happened pressure drawn behind the now marker.
  ///
  /// Five days, not the twelve hours it started at. The daily history chart
  /// carries a month at one reading a day; this is the only surface in the app
  /// with the pressure the user actually lived HOUR by hour, which is what a
  /// drop the user remembers has to be checked against. WeatherKit returns the
  /// hourly series in one request whatever window is asked for and the backend
  /// already clamps `hoursBack` at 240, so the width is free — but the cache key
  /// includes it, so changing this number orphans the old cache entries and
  /// costs one WeatherKit call per cell to refill.
  static const int contextHours = 120;

  /// UTC instant the forecast was fetched (the chart's "now" marker).
  final DateTime generatedAt;

  /// Ascending by time, spanning [generatedAt]−[contextHours] … +[forecastDays] days.
  final List<PressurePoint> points;
}
