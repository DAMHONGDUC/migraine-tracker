import 'package:meta/meta.dart';

/// The soonest upcoming medication reminder relative to "now", for the
/// dashboard banner. Computed by [NextReminderCalculator].
@immutable
class NextReminder {
  const NextReminder({
    required this.medicationId,
    required this.medicationName,
    required this.minuteOfDay,
    required this.timeUntil,
  });

  /// The medication this reminder belongs to — used to scroll/highlight its
  /// card on the Medications tab.
  final String medicationId;
  final String medicationName;

  /// Local time-of-day of the reminder, minutes past midnight (0–1439).
  final int minuteOfDay;

  /// How long from now until it next fires (always < 24h — reminders repeat
  /// daily).
  final Duration timeUntil;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;
}
