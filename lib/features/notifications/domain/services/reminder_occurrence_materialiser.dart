import '../../../medications/domain/entities/medication_reminder.dart';
import '../entities/app_notification.dart';
import '../enums/notification_kind.dart';

/// Rebuilds the reminder half of the notification list from the reminders
/// themselves.
///
/// Pure and deterministic, which is the whole point: reminders already sync,
/// so every device runs this over the same input and derives the same ids
/// (hard rule 15). That is what makes the list match across devices without
/// any of them uploading a reminder notification first.
///
/// It answers "which reminders have already come round", not "which
/// notifications did iOS actually display" — the plugin cannot tell us the
/// second one while the app is dead, and a reminder that was set and armed is
/// what the user saw.
class ReminderOccurrenceMaterialiser {
  const ReminderOccurrenceMaterialiser();

  /// How far back the list reaches.
  ///
  /// A fixed window, deliberately not a per-device cursor: a cursor is
  /// something only one device knows, so a phone installed last week would
  /// show less history than one installed last month. Recomputing the whole
  /// window every run costs nothing, because ids are derived and the store
  /// only inserts what is missing.
  static const Duration defaultWindow = Duration(days: 30);

  /// Occurrences of every enabled reminder that have already come round,
  /// oldest first.
  ///
  /// Two knowingly imperfect edges, both preferred to the alternative:
  /// - a reminder whose time was changed re-derives its *past* occurrences at
  ///   the new time, because the old one is not recorded anywhere;
  /// - a disabled reminder stops producing occurrences entirely, so a device
  ///   that never ran while it was on learns its history from sync instead.
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

      // A reminder created yesterday has no history from last month. Null
      // createdAt means "unknown" (a row from before schema v8), and then the
      // window is the only bound there is.
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

  /// Walks calendar days rather than adding 24h at a time: across a DST
  /// boundary a fixed day of duration lands an hour off and either skips a
  /// date or repeats one, which would derive an id no other device agrees on.
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
        kind: NotificationKind.medicationReminder,
        occurredAt: occurredAt,
        medicationId: reminder.medicationId,
        reminderId: reminder.id,
      );
    }
  }
}
