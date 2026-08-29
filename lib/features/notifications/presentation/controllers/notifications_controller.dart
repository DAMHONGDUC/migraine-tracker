import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../medications/domain/entities/medication_reminder.dart';
import '../../../medications/providers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/services/pressure_alert_mapper.dart';
import '../../domain/services/reminder_occurrence_materialiser.dart';
import '../../providers.dart';

/// Keeps the notification list up to date, and marks it read.
class NotificationsController {
  const NotificationsController(this._ref);

  final Ref _ref;

  static const ReminderOccurrenceMaterialiser _materialiser =
      ReminderOccurrenceMaterialiser();

  /// Rebuilds the reminder half of the list from the reminders themselves.
  Future<void> materialise() async {
    try {
      final List<MedicationReminder> reminders = await _ref
          .read(medicationReminderRepositoryProvider)
          .getAllEnabled();
      final List<AppNotification> occurrences = _materialiser.occurrences(
        reminders,
        now: DateTime.now(),
      );

      await _ref.read(notificationRepositoryProvider).addMissing(occurrences);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notifications,
        'Materialising reminder notifications failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Records a pressure alert that arrived as a push while the app was open.
  Future<void> recordPush(Map<String, dynamic> data) async {
    final AppNotification? alert = PressureAlertMapper.fromData(data);

    if (alert == null) return;
    try {
      await _ref.read(notificationRepositoryProvider).addMissing(
        <AppNotification>[alert],
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notifications,
        'Recording a pushed alert failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Catches up the pressure alert that arrived while the app was shut.
  Future<void> reconcileLastAlert() async {
    try {
      final AppNotification? alert = await _ref
          .read(lastAlertRepositoryProvider)
          .latest();

      if (alert == null) return;
      await _ref.read(notificationRepositoryProvider).addMissing(
        <AppNotification>[alert],
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notifications,
        'Reconciling the last pressure alert failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The row a tapped reminder notification leads to, or null when there is none to open.
  Future<String?> reminderTapTarget(String reminderId) async {
    SdLogger.action(
      LogTagConstant.notifications,
      'Open tapped reminder',
      reminderId,
    );
    try {
      await materialise();

      final AppNotification? latest = await _ref
          .read(notificationRepositoryProvider)
          .latestForReminder(reminderId);

      return latest?.id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notifications,
        'Opening a tapped reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// The row a tapped pressure alert leads to, or null when the push is not one.
  Future<String?> pushTapTarget(Map<String, dynamic> data) async {
    final AppNotification? alert = PressureAlertMapper.fromData(data);

    if (alert == null) return null;
    SdLogger.action(
      LogTagConstant.notifications,
      'Open tapped alert',
      alert.id,
    );
    await recordPush(data);

    return alert.id;
  }

  /// Called when one notification's detail screen opens — the only thing that counts as reading it.
  Future<void> markRead(String id) async {
    SdLogger.action(LogTagConstant.notifications, 'Mark notification read', id);
    try {
      await _ref
          .read(notificationRepositoryProvider)
          .markRead(id, DateTime.now().toUtc());
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notifications,
        'Marking a notification read failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
