import 'package:meta/meta.dart';

@immutable
class PressurePoint {
  const PressurePoint({required this.time, required this.pressureHpa});

  /// UTC, hour resolution.
  final DateTime time;
  final double pressureHpa;
}

/// Hourly pressure around now: ~12h of context behind, 48h of forecast
/// ahead — what the premium forecast chart renders.
@immutable
class PressureForecast {
  const PressureForecast({required this.generatedAt, required this.points});

  /// UTC instant the forecast was fetched (the chart's "now" marker).
  final DateTime generatedAt;

  /// Ascending by time, spanning [generatedAt]−12h … +48h.
  final List<PressurePoint> points;
}
