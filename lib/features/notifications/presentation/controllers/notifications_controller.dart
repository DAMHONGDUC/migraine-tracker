import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../medications/domain/entities/medication_reminder.dart';
import '../../../medications/providers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/services/pressure_alert_mapper.dart';
import '../../domain/services/reminder_occurrence_materialiser.dart';
import '../../providers.dart';

/// Keeps the notification list up to date, and marks it read.
///
/// [materialise] is safe to call as often as you like — ids are derived and
/// the store only inserts what is missing (hard rule 16) — which is why it
/// runs on every launch and every resume rather than tracking when it last
/// ran.
class NotificationsController {
  const NotificationsController(this._ref);

  final Ref _ref;

  static const ReminderOccurrenceMaterialiser _materialiser =
      ReminderOccurrenceMaterialiser();

  /// Rebuilds the reminder half of the list from the reminders themselves.
  ///
  /// Needs no account: reminders are on-device, so this works for an
  /// anonymous user too and the list is never empty just because nobody
  /// signed in.
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
      AppLogger.error(
        'Materialising reminder notifications failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Records a pressure alert that arrived as a push while the app was
  /// open.
  ///
  /// Ignores anything that is not a pressure alert, or is missing what a
  /// row needs: a push comes from outside the app, so a malformed one is
  /// dropped rather than allowed to throw inside a platform callback.
  Future<void> recordPush(Map<String, dynamic> data) async {
    final AppNotification? alert = PressureAlertMapper.fromData(data);

    if (alert == null) return;
    try {
      await _ref.read(notificationRepositoryProvider).addMissing(
        <AppNotification>[alert],
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Recording a pushed alert failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// The row a tapped reminder notification leads to, or null when there is
  /// none to open.
  ///
  /// Materialises first: reminder occurrences are derived rather than
  /// recorded as they fire, so the one the user just tapped may not exist
  /// until this runs.
  Future<String?> reminderTapTarget(String reminderId) async {
    AppLogger.action('Open tapped reminder', reminderId);
    try {
      await materialise();

      final AppNotification? latest = await _ref
          .read(notificationRepositoryProvider)
          .latestForReminder(reminderId);

      return latest?.id;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Opening a tapped reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// The row a tapped pressure alert leads to, or null when the push is not
  /// one.
  ///
  /// Records it on the way through: an alert that arrived while the app was
  /// shut has no row yet, and [recordPush] is idempotent (hard rule 16).
  Future<String?> pushTapTarget(Map<String, dynamic> data) async {
    final AppNotification? alert = PressureAlertMapper.fromData(data);

    if (alert == null) return null;
    AppLogger.action('Open tapped alert', alert.id);
    await recordPush(data);

    return alert.id;
  }

  /// Called when one notification's detail screen opens — the only thing
  /// that counts as reading it.
  Future<void> markRead(String id) async {
    AppLogger.action('Mark notification read', id);
    try {
      await _ref
          .read(notificationRepositoryProvider)
          .markRead(id, DateTime.now().toUtc());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Marking a notification read failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
