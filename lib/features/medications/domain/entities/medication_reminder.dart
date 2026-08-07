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
  /// not one each. The one past this, anywhere, is where premium is pitched.
  ///
  /// Two, not one: a preventive taken morning and evening — or one preventive
  /// plus a supplement — is the ordinary regimen, and a limit that blocks it
  /// on day one reads as broken rather than tiered.
  static const int freeLimit = 2;

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
