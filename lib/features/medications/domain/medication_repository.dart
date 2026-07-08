import 'medication.dart';

/// Contract for the user's saved medications.
abstract interface class MedicationRepository {
  Stream<List<Medication>> watchAll();

  Future<void> upsert(Medication medication);

  Future<void> deleteById(String id);

  /// GDPR wipe.
  Future<void> deleteAll();
}
