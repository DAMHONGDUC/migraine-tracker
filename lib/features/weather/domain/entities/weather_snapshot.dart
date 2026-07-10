import 'package:meta/meta.dart';

/// Weather conditions captured (or backfilled) at the time of an attack.
///
/// [pressureDelta24hHpa] is the pressure change over the 24 hours *before*
/// [capturedAt]; negative values mean the pressure dropped.
@immutable
class WeatherSnapshot {
  WeatherSnapshot({
    required DateTime capturedAt,
    required this.pressureHpa,
    required this.pressureDelta24hHpa,
    this.humidityPercent,
    this.temperatureCelsius,
  }) : capturedAt = capturedAt.toUtc();

  final DateTime capturedAt;
  final double pressureHpa;
  final double pressureDelta24hHpa;
  final double? humidityPercent;
  final double? temperatureCelsius;

  @override
  bool operator ==(Object other) =>
      other is WeatherSnapshot &&
      other.capturedAt == capturedAt &&
      other.pressureHpa == pressureHpa &&
      other.pressureDelta24hHpa == pressureDelta24hHpa &&
      other.humidityPercent == humidityPercent &&
      other.temperatureCelsius == temperatureCelsius;

  @override
  int get hashCode => Object.hash(
    capturedAt,
    pressureHpa,
    pressureDelta24hHpa,
    humidityPercent,
    temperatureCelsius,
  );
}
