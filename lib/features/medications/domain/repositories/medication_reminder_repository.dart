import '../entities/medication_reminder.dart';

/// Stores daily medication reminders. Scheduling the actual local
/// notifications is a separate concern (NotificationScheduler).
abstract interface class MedicationReminderRepository {
  /// All reminders with their medication name resolved, ordered by time.
  Stream<List<MedicationReminderView>> watchAll();

  Future<List<MedicationReminder>> getAllEnabled();

  Future<void> upsert(MedicationReminder reminder);

  Future<void> deleteById(String id);

  /// GDPR wipe.
  Future<void> deleteAll();
}

/// A reminder joined with its medication's name, for list rendering.
class MedicationReminderView {
  const MedicationReminderView({
    required this.reminder,
    required this.medicationName,
  });

  final MedicationReminder reminder;
  final String medicationName;
}
