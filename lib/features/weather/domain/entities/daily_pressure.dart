import 'package:meta/meta.dart';

/// One day's pressure reading, attack or no attack.
///
/// The point of it is the days with no attack: those are the denominator the
/// pressure correlation needs to say anything about risk rather than about
/// the local climate.
@immutable
class DailyPressure {
  DailyPressure({
    required DateTime day,
    required this.pressureHpa,
    required this.pressureDelta24hHpa,
  }) : day = DateTime(day.year, day.month, day.day);

  /// Local midnight — the identity of a day as the user lived it.
  final DateTime day;

  final double pressureHpa;

  /// Change over the 24 hours before the reading; negative means falling.
  final double pressureDelta24hHpa;

  /// Whether this day counts as a rapid drop at [thresholdHpa].
  bool isDrop(double thresholdHpa) => pressureDelta24hHpa <= -thresholdHpa;

  @override
  bool operator ==(Object other) =>
      other is DailyPressure &&
      other.day == day &&
      other.pressureHpa == pressureHpa &&
      other.pressureDelta24hHpa == pressureDelta24hHpa;

  @override
  int get hashCode => Object.hash(day, pressureHpa, pressureDelta24hHpa);
}
