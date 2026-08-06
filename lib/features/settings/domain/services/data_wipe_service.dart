import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';
import '../../../medications/domain/services/notification_scheduler.dart';
import '../../../sync/domain/services/attack_sync_service.dart';
import '../repositories/export_record_repository.dart';
import 'export_file_store.dart';

/// GDPR "delete everything" (hard rule 8): the on-device database, past
/// exports, and the account's synced copy.
///
/// Still missing, and tracked in `docs/REMAINING_WORK.md`: the `users/{uid}`
/// document, the FCM token, and deleting the Firebase Auth account itself
/// (App Store 5.1.1(v)).
class DataWipeService {
  const DataWipeService(
    this._attacks,
    this._medications,
    this._notifications,
    this._exportRecords,
    this._exportFiles,
    this._auth,
    this._sync,
  );

  final AttackRepository _attacks;
  final MedicationRepository _medications;
  final NotificationScheduler _notifications;
  final ExportRecordRepository _exportRecords;
  final ExportFileStore _exportFiles;
  final AuthRepository _auth;
  final AttackSyncService _sync;

  Future<void> wipeAll() async {
    // The server copy goes FIRST, and a failure here aborts the whole wipe.
    // Wiping the device first would leave the cloud history intact with
    // nothing left to say it should go — and the next sync would pull every
    // deleted attack straight back down.
    await _wipeRemote();

    await _attacks.deleteAll();
    // DB cascade drops reminder rows but never reaches the OS — cancel or a notification keeps firing.
    await _notifications.cancelAll();
    await _medications.deleteAll();
    // Past exports are full copies of the deleted data — leave them and the wipe is incomplete.
    await _exportFiles.deleteAll();
    await _exportRecords.deleteAll();
  }

  /// Nothing to do without an account: an anonymous session never uploaded
  /// anything, so there is no server copy to chase.
  Future<void> _wipeRemote() async {
    final AuthUser? user = _auth.currentUser;

    if (user == null || !user.isSignedIn) return;
    await _sync.wipeRemote(user.uid);
  }
}
