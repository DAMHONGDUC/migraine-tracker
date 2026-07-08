import 'package:drift/drift.dart';

import '../../domain/models/medication.dart';
import '../db/app_database.dart';

/// The user's saved medications, feeding the picker in the 3-tap log flow.
class MedicationRepository {
  const MedicationRepository(this._db);

  final AppDatabase _db;

  Stream<List<Medication>> watchAll() {
    final query = _db.select(_db.medications)
      ..orderBy([(m) => OrderingTerm.asc(m.name)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => Medication(id: row.id, name: row.name))
          .toList(),
    );
  }

  Future<void> upsert(Medication medication) => _db
      .into(_db.medications)
      .insertOnConflictUpdate(
        MedicationsCompanion.insert(id: medication.id, name: medication.name),
      );

  Future<void> deleteById(String id) =>
      (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();

  /// GDPR wipe.
  Future<void> deleteAll() => _db.delete(_db.medications).go();
}
