import 'package:meta/meta.dart';

/// A daily local reminder to take a medication.
@immutable
class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.minuteOfDay,
    this.enabled = true,
  });

  /// How many reminders a free user may create, across every medication —
  /// not one each. The second one anywhere is where premium is pitched.
  static const int freeLimit = 1;

  final String id;
  final String medicationId;

  /// Local time-of-day as minutes past midnight (0–1439).
  final int minuteOfDay;
  final bool enabled;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;

  MedicationReminder copyWith({int? minuteOfDay, bool? enabled}) =>
      MedicationReminder(
        id: id,
        medicationId: medicationId,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        enabled: enabled ?? this.enabled,
      );
}
