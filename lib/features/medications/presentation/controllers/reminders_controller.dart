import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../providers.dart';

/// Orchestrates reminders: persists them AND (re)schedules the matching OS
/// notifications. The notification body strings are passed in from the UI
/// (l10n lives there, not in the controller).
class RemindersController {
  const RemindersController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<bool> add({
    required String medicationId,
    required String medicationName,
    required int minuteOfDay,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    final granted = await _ref
        .read(notificationSchedulerProvider)
        .ensurePermission();
    if (!granted) {
      AppLogger.warning('Reminder not added: notification permission denied');
      return false;
    }

    final reminder = MedicationReminder(
      id: _uuid.v4(),
      medicationId: medicationId,
      minuteOfDay: minuteOfDay,
    );
    AppLogger.action('Add reminder', {
      'medication': medicationName,
      'minuteOfDay': minuteOfDay,
    });
    await _ref.read(medicationReminderRepositoryProvider).upsert(reminder);
    await _ref
        .read(notificationSchedulerProvider)
        .schedule(
          reminder,
          medicationName: medicationName,
          title: notificationTitle,
          bodyTemplate: notificationBody,
        );
    return true;
  }

  /// Changes an existing reminder's time of day and reschedules its
  /// notification (which fires at the new time). A disabled reminder just
  /// updates its stored time — [NotificationScheduler.schedule] cancels the
  /// old one and skips scheduling until it's re-enabled.
  Future<void> updateTime(
    MedicationReminder reminder, {
    required String medicationName,
    required int minuteOfDay,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    AppLogger.action('Edit reminder time', {
      'id': reminder.id,
      'minuteOfDay': minuteOfDay,
    });
    final updated = reminder.copyWith(minuteOfDay: minuteOfDay);
    await _ref.read(medicationReminderRepositoryProvider).upsert(updated);
    await _ref
        .read(notificationSchedulerProvider)
        .schedule(
          updated,
          medicationName: medicationName,
          title: notificationTitle,
          bodyTemplate: notificationBody,
        );
  }

  Future<void> setEnabled(
    MedicationReminder reminder, {
    required String medicationName,
    required String notificationTitle,
    required String notificationBody,
    required bool enabled,
  }) async {
    AppLogger.action('Toggle reminder', {'id': reminder.id, 'enabled': enabled});
    final updated = reminder.copyWith(enabled: enabled);
    await _ref.read(medicationReminderRepositoryProvider).upsert(updated);
    final scheduler = _ref.read(notificationSchedulerProvider);
    if (enabled) {
      await scheduler.schedule(
        updated,
        medicationName: medicationName,
        title: notificationTitle,
        bodyTemplate: notificationBody,
      );
    } else {
      await scheduler.cancel(reminder.id);
    }
  }

  /// Debug-only: fires a one-off notification shortly from now so a developer
  /// can confirm delivery without waiting for a real reminder. Strings come
  /// from the UI (l10n).
  Future<void> sendTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    AppLogger.action('Send test notification', {'delaySeconds': delay.inSeconds});
    await _ref
        .read(notificationSchedulerProvider)
        .scheduleTest(title: title, body: body, delay: delay);
  }

  Future<void> delete(String reminderId) async {
    AppLogger.action('Delete reminder', reminderId);
    await _ref.read(medicationReminderRepositoryProvider).deleteById(reminderId);
    await _ref.read(notificationSchedulerProvider).cancel(reminderId);
  }
}
