import 'package:meta/meta.dart';

/// A daily local reminder to take a medication.
@immutable
class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.minuteOfDay,
    this.enabled = true,
    this.createdAt,
  });

  final String id;
  final String medicationId;

  /// Local time-of-day as minutes past midnight (0–1439).
  final int minuteOfDay;
  final bool enabled;

  /// When this reminder was created (UTC), or null for one saved before the
  /// column existed. It bounds how far back the notification list may
  /// materialise past occurrences, so it has to mean the same thing on every
  /// device — which is why it travels in the sync payload.
  final DateTime? createdAt;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;

  MedicationReminder copyWith({int? minuteOfDay, bool? enabled}) =>
      MedicationReminder(
        id: id,
        medicationId: medicationId,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
      );
}
