import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/services/notification_scheduler.dart';
import '../../providers.dart';

/// Orchestrates reminders: persists them AND (re)schedules the matching OS
/// notifications. The notification body strings are passed in from the UI
/// (l10n lives there, not in the controller).
class RemindersController {
  const RemindersController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Persists a new reminder and schedules its notification. Notification
  /// permission is the caller's responsibility now (via `AppPermission`), so
  /// this no longer prompts.
  Future<void> add({
    required String medicationId,
    required String medicationName,
    required int minuteOfDay,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    try {
      final reminder = MedicationReminder(
        id: _uuid.v4(),
        medicationId: medicationId,
        minuteOfDay: minuteOfDay,
      );

      AppLogger.action('Add reminder', {
        'medication': medicationName,
        'minuteOfDay': minuteOfDay,
      });
      AppAnalytics.logReminderAdded();
      await _ref.read(medicationReminderRepositoryProvider).upsert(reminder);
      await _ref
          .read(notificationSchedulerProvider)
          .schedule(
            reminder,
            medicationName: medicationName,
            title: notificationTitle,
            bodyTemplate: notificationBody,
            sound: _ref.read(reminderSoundProvider),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Add reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
    try {
      final updated = reminder.copyWith(minuteOfDay: minuteOfDay);

      AppLogger.action('Edit reminder time', {
        'id': reminder.id,
        'minuteOfDay': minuteOfDay,
      });
      AppAnalytics.logReminderTimeEdited();
      await _ref.read(medicationReminderRepositoryProvider).upsert(updated);
      await _ref
          .read(notificationSchedulerProvider)
          .schedule(
            updated,
            medicationName: medicationName,
            title: notificationTitle,
            bodyTemplate: notificationBody,
            sound: _ref.read(reminderSoundProvider),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Edit reminder time failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> setEnabled(
    MedicationReminder reminder, {
    required String medicationName,
    required String notificationTitle,
    required String notificationBody,
    required bool enabled,
  }) async {
    try {
      final updated = reminder.copyWith(enabled: enabled);
      final scheduler = _ref.read(notificationSchedulerProvider);

      AppLogger.action('Toggle reminder', {
        'id': reminder.id,
        'enabled': enabled,
      });
      AppAnalytics.logReminderToggled(enabled: enabled);
      await _ref.read(medicationReminderRepositoryProvider).upsert(updated);
      if (enabled) {
        await scheduler.schedule(
          updated,
          medicationName: medicationName,
          title: notificationTitle,
          bodyTemplate: notificationBody,
          sound: _ref.read(reminderSoundProvider),
        );
      } else {
        await scheduler.cancel(reminder.id);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Toggle reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Re-lays the OS notification for every enabled reminder.
  ///
  /// Sync moves the rows but not the schedules: a notification is registered
  /// with the OS of the device that made it, so a reminder pulled from
  /// another phone would sit in the list and never fire. Called after a pull
  /// brought reminders down.
  ///
  /// Never throws — this is background work behind a sync that nothing waits
  /// on, and a reminder that failed to schedule is fixed by the next pull or
  /// by the user touching it.
  Future<void> rescheduleAll() async {
    try {
      final List<MedicationReminder> reminders = await _ref
          .read(medicationReminderRepositoryProvider)
          .getAllEnabled();
      final List<Medication> medications = await _ref
          .read(medicationRepositoryProvider)
          .getAll();
      final Map<String, String> names = <String, String>{
        for (final Medication medication in medications)
          medication.id: medication.name,
      };
      final AppLocalizations l10n = lookupAppLocalizations(_notificationLocale);
      final NotificationScheduler scheduler = _ref.read(
        notificationSchedulerProvider,
      );
      final bool sound = _ref.read(reminderSoundProvider);

      AppLogger.info('Rescheduling reminders', reminders.length);
      for (final MedicationReminder reminder in reminders) {
        final String? medicationName = names[reminder.medicationId];

        // The medication has not arrived yet; the pull that brings it will
        // bring this reminder's schedule with it.
        if (medicationName == null) continue;
        await scheduler.schedule(
          reminder,
          medicationName: medicationName,
          title: l10n.reminderNotificationTitle,
          bodyTemplate: l10n.reminderNotificationBody('{name}'),
          sound: sound,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Rescheduling reminders failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The user's chosen language, or the platform's — falling back to the
  /// template locale when neither is one this app ships.
  Locale get _notificationLocale {
    final Locale chosen =
        _ref.read(localeControllerProvider) ??
        PlatformDispatcher.instance.locale;

    return AppLocalizations.supportedLocales.any(
          (Locale locale) => locale.languageCode == chosen.languageCode,
        )
        ? Locale(chosen.languageCode)
        : const Locale('en');
  }

  /// Debug-only: fires a one-off notification shortly from now so a developer
  /// can confirm delivery without waiting for a real reminder. Strings come
  /// from the UI (l10n).
  Future<void> sendTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    AppLogger.action('Send test notification', {
      'delaySeconds': delay.inSeconds,
    });
    try {
      await _ref
          .read(notificationSchedulerProvider)
          .scheduleTest(
            title: title,
            body: body,
            delay: delay,
            sound: _ref.read(reminderSoundProvider),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Send test notification failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String reminderId) async {
    AppLogger.action('Delete reminder', reminderId);
    AppAnalytics.logReminderDeleted();
    try {
      await _ref
          .read(medicationReminderRepositoryProvider)
          .deleteById(reminderId);
      await _ref.read(notificationSchedulerProvider).cancel(reminderId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
