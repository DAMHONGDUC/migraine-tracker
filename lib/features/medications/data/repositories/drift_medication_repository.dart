import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';

/// Drift-backed [MedicationRepository].
class DriftMedicationRepository implements MedicationRepository {
  const DriftMedicationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Medication>> watchAll() {
    final query = _db.select(_db.medications)
      ..orderBy([(m) => OrderingTerm.asc(m.name)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => Medication(id: row.id, name: row.name))
          .toList(),
    );
  }

  @override
  Future<void> upsert(Medication medication) => _db
      .into(_db.medications)
      .insertOnConflictUpdate(
        MedicationsCompanion.insert(id: medication.id, name: medication.name),
      );

  @override
  Future<void> deleteById(String id) =>
      (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();

  /// GDPR wipe.
  @override
  Future<void> deleteAll() => _db.delete(_db.medications).go();
}
