import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../medications/domain/services/notification_scheduler.dart';

/// GDPR "delete everything" (hard rule 8). v1 wipes the on-device database;
/// the auth/sync and alerts phases MUST extend this with Firestore doc +
/// synced attacks deletion, FCM token revocation, and account deletion.
class DataWipeService {
  const DataWipeService(this._attacks, this._medications, this._notifications);

  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final NotificationScheduler _notifications;

  Future<void> wipeAll() async {
    await _attacks.deleteAll();
    // Deleting medications cascades their reminder ROWS at the DB level,
    // but that cascade never reaches the OS — without this, an already
    // scheduled "time for your medication" notification keeps firing after
    // the user asked for everything to be deleted.
    await _notifications.cancelAll();
    await _medications.deleteAll();
  }
}
