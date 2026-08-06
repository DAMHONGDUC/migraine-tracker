import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../medications/domain/services/notification_scheduler.dart';
import '../repositories/export_record_repository.dart';
import 'export_file_store.dart';

/// GDPR "delete everything" (hard rule 8). v1 wipes the on-device database;
/// the auth/sync and alerts phases MUST extend this with Firestore doc +
/// synced attacks deletion, FCM token revocation, and account deletion.
class DataWipeService {
  const DataWipeService(
    this._attacks,
    this._medications,
    this._notifications,
    this._exportRecords,
    this._exportFiles,
  );

  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final NotificationScheduler _notifications;
  final ExportRecordRepository _exportRecords;
  final ExportFileStore _exportFiles;

  Future<void> wipeAll() async {
    await _attacks.deleteAll();
    // DB cascade drops reminder rows but never reaches the OS — cancel or a notification keeps firing.
    await _notifications.cancelAll();
    await _medications.deleteAll();
    // Past exports are full copies of the deleted data — leave them and the wipe is incomplete.
    await _exportFiles.deleteAll();
    await _exportRecords.deleteAll();
  }
}
