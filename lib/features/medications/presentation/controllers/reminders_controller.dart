import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/locale_utils.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../notifications/domain/services/notification_scheduler.dart';
import '../../../notifications/providers.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../providers.dart';

/// Orchestrates reminders: persists them AND (re)schedules the matching OS notifications.
class RemindersController {
  const RemindersController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Persists a new reminder and schedules its notification.
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

      SdLogger.action(LogTagConstant.reminders, 'Add reminder', {
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
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
        'Add reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Changes an existing reminder's time of day and reschedules its notification (which fires at the new time).
  Future<void> updateTime(
    MedicationReminder reminder, {
    required String medicationName,
    required int minuteOfDay,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    try {
      final updated = reminder.copyWith(minuteOfDay: minuteOfDay);

      SdLogger.action(LogTagConstant.reminders, 'Edit reminder time', {
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
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
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

      SdLogger.action(LogTagConstant.reminders, 'Toggle reminder', {
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
        );
      } else {
        await scheduler.cancel(reminder.id);
      }
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
        'Toggle reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Re-lays the OS notification for every enabled reminder.
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
      final AppLocalizations l10n = lookupAppLocalizations(
        LocaleUtils.resolve(
          chosen: _ref.read(localeControllerProvider),
          platform: PlatformDispatcher.instance.locale,
          supported: AppLocalizations.supportedLocales,
        ),
      );
      final NotificationScheduler scheduler = _ref.read(
        notificationSchedulerProvider,
      );

      SdLogger.info(
        LogTagConstant.reminders,
        'Rescheduling reminders',
        reminders.length,
      );
      for (final MedicationReminder reminder in reminders) {
        final String? medicationName = names[reminder.medicationId];

        // The medication has not arrived yet; the pull that brings it will bring this reminder's schedule with it.
        if (medicationName == null) continue;
        await scheduler.schedule(
          reminder,
          medicationName: medicationName,
          title: l10n.reminderNotificationTitle,
          bodyTemplate: l10n.reminderNotificationBody('{name}'),
        );
      }
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
        'Rescheduling reminders failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Debug-only: fires a one-off notification shortly from now so a developer can confirm delivery without waiting for a real reminder.
  Future<void> sendTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    SdLogger.action(LogTagConstant.reminders, 'Send test notification', {
      'delaySeconds': delay.inSeconds,
    });
    try {
      await _ref
          .read(notificationSchedulerProvider)
          .scheduleTest(title: title, body: body, delay: delay);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
        'Send test notification failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String reminderId) async {
    SdLogger.action(LogTagConstant.reminders, 'Delete reminder', reminderId);
    AppAnalytics.logReminderDeleted();
    try {
      await _ref
          .read(medicationReminderRepositoryProvider)
          .deleteById(reminderId);
      await _ref.read(notificationSchedulerProvider).cancel(reminderId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.reminders,
        'Delete reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
