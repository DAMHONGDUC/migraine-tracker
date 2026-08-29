import '../../../medications/domain/entities/medication_reminder.dart';
import '../entities/app_notification.dart';
import '../enums/notification_type.dart';

/// Rebuilds the reminder half of the notification list from the reminders themselves.
class ReminderOccurrenceMaterialiser {
  const ReminderOccurrenceMaterialiser();

  /// How far back the list reaches.
  static const Duration defaultWindow = Duration(days: 30);

  /// Occurrences of every enabled reminder that have already come round, oldest first.
  List<AppNotification> occurrences(
    List<MedicationReminder> reminders, {
    required DateTime now,
    Duration window = defaultWindow,
  }) {
    final DateTime localNow = now.toLocal();
    final DateTime windowStart = localNow.subtract(window);
    final List<AppNotification> result = <AppNotification>[];

    for (final MedicationReminder reminder in reminders) {
      if (!reminder.enabled) continue;

      // A reminder created yesterday has no history from last month.
      final DateTime? createdAt = reminder.createdAt?.toLocal();
      final DateTime start =
          createdAt == null || createdAt.isBefore(windowStart)
          ? windowStart
          : createdAt;

      result.addAll(_occurrencesOf(reminder, from: start, until: localNow));
    }

    result.sort(
      (AppNotification a, AppNotification b) =>
          a.occurredAt.compareTo(b.occurredAt),
    );
    return result;
  }

  /// Walks calendar days rather than adding 24h at a time.
  Iterable<AppNotification> _occurrencesOf(
    MedicationReminder reminder, {
    required DateTime from,
    required DateTime until,
  }) sync* {
    for (int day = 0; ; day++) {
      final DateTime at = DateTime(
        from.year,
        from.month,
        from.day + day,
        reminder.hour,
        reminder.minute,
      );

      if (at.isAfter(until)) return;
      if (at.isBefore(from)) continue;

      final DateTime occurredAt = at.toUtc();
      yield AppNotification(
        id: AppNotification.reminderOccurrenceId(reminder.id, occurredAt),
        type: NotificationType.medicationReminder,
        occurredAt: occurredAt,
        medicationId: reminder.medicationId,
        reminderId: reminder.id,
      );
    }
  }
}
