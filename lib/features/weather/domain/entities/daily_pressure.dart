import 'package:meta/meta.dart';

/// One day's weather reading, attack or no attack.
@immutable
class DailyPressure {
  DailyPressure({
    required DateTime day,
    required this.pressureHpa,
    required this.pressureDelta24hHpa,
    this.humidityPercent,
    this.temperatureCelsius,
  }) : day = DateTime(day.year, day.month, day.day);

  /// Local midnight — the identity of a day as the user lived it.
  final DateTime day;

  final double pressureHpa;

  /// Change over the 24 hours before the reading; negative means falling.
  final double pressureDelta24hHpa;

  /// Null on every reading taken before these were recorded — absent, never zero, which would read as a desert.
  final double? humidityPercent;
  final double? temperatureCelsius;

  /// Whether this day counts as a rapid drop at [thresholdHpa].
  bool isDrop(double thresholdHpa) => pressureDelta24hHpa <= -thresholdHpa;

  @override
  bool operator ==(Object other) =>
      other is DailyPressure &&
      other.day == day &&
      other.pressureHpa == pressureHpa &&
      other.pressureDelta24hHpa == pressureDelta24hHpa &&
      other.humidityPercent == humidityPercent &&
      other.temperatureCelsius == temperatureCelsius;

  @override
  int get hashCode => Object.hash(
    day,
    pressureHpa,
    pressureDelta24hHpa,
    humidityPercent,
    temperatureCelsius,
  );
}
