import '../../../attacks/domain/repositories/attack_repository.dart';
import '../../../medications/domain/repositories/medication_repository.dart';

/// GDPR "delete everything" (hard rule 8). v1 wipes the on-device database;
/// the auth/sync and alerts phases MUST extend this with Firestore doc +
/// synced attacks deletion, FCM token revocation, and account deletion.
class DataWipeService {
  const DataWipeService(this._attacks, this._medications);

  final AttackRepository _attacks;
  final MedicationRepository _medications;

  Future<void> wipeAll() async {
    await _attacks.deleteAll();
    await _medications.deleteAll();
  }
}
