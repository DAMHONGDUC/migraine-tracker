import 'package:meta/meta.dart';

@immutable
class PressurePoint {
  const PressurePoint({required this.time, required this.pressureHpa});

  /// UTC, hour resolution.
  final DateTime time;
  final double pressureHpa;
}

/// Hourly pressure around now: ~12h of context behind, a week of forecast
/// ahead — what the premium forecast chart renders.
@immutable
class PressureForecast {
  const PressureForecast({required this.generatedAt, required this.points});

  /// How far ahead the chart reaches.
  ///
  /// Seven days, not two. WeatherKit's hourly series runs to 240 hours and
  /// arrives in ONE request whatever window is asked for, so the extra five
  /// days cost neither an API call nor a byte of quota — and a pressure
  /// system a user can see coming on Tuesday is one they can plan around.
  static const int forecastDays = 7;

  /// Hours of already-happened pressure drawn behind the now marker, so a
  /// rise or fall in progress has a shape rather than a single point.
  static const int contextHours = 12;

  /// UTC instant the forecast was fetched (the chart's "now" marker).
  final DateTime generatedAt;

  /// Ascending by time, spanning [generatedAt]−[contextHours] …
  /// +[forecastDays] days.
  final List<PressurePoint> points;
}
