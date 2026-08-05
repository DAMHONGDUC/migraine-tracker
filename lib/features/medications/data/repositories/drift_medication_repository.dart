import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';

/// Drift-backed [MedicationRepository].
class DriftMedicationRepository implements MedicationRepository {
  const DriftMedicationRepository(this._db);

  final AppDatabase _db;

  /// One place the row shape becomes the domain model.
  Medication _toDomain(MedicationRow row) =>
      Medication(id: row.id, name: row.name, createdAt: row.createdAt);

  @override
  Stream<List<Medication>> watchAll() {
    final query = _db.select(_db.medications)
      ..orderBy([(m) => OrderingTerm.asc(m.name)]);

    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Medication>> getAll() async {
    final query = _db.select(_db.medications)
      ..orderBy([(m) => OrderingTerm.asc(m.name)]);
    final List<MedicationRow> rows = await query.get();

    return rows.map(_toDomain).toList();
  }

  // - Callers own createdAt: stamped once on add, threaded unchanged on rename.
  // - Repository never invents or overwrites it, so rename can't reset it.
  @override
  Future<void> upsert(Medication medication) => _db
      .into(_db.medications)
      .insertOnConflictUpdate(
        MedicationsCompanion.insert(
          id: medication.id,
          name: medication.name,
          createdAt: Value(medication.createdAt),
        ),
      );

  @override
  Future<void> deleteById(String id) =>
      (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();

  /// GDPR wipe.
  @override
  Future<void> deleteAll() => _db.delete(_db.medications).go();
}
