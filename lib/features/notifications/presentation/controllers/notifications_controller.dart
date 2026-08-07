import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../medications/domain/entities/medication_reminder.dart';
import '../../../medications/providers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/services/reminder_occurrence_materialiser.dart';
import '../../providers.dart';

/// Keeps the notification list up to date, and marks it read.
///
/// [materialise] is safe to call as often as you like — ids are derived and
/// the store only inserts what is missing (hard rule 15) — which is why it
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

  /// Called when the list screen opens. One pass over everything unread —
  /// opening the list is a single act, and the rows only differ by when they
  /// arrived.
  Future<void> markAllRead() async {
    AppLogger.action('Mark notifications read');
    try {
      await _ref
          .read(notificationRepositoryProvider)
          .markAllRead(DateTime.now().toUtc());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Marking notifications read failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
