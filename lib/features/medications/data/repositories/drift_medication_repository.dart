import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
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

  // - Callers own createdAt: stamped once on add, threaded unchanged on rename. - Repository never invents or overwrites it, so rename can't reset it.
  @override
  Future<void> upsert(Medication medication) {
    return _db.transaction(() async {
      final MedicationRow? existing = await (_db.select(
        _db.medications,
      )..where((m) => m.id.equals(medication.id))).getSingleOrNull();

      await _db
          .into(_db.medications)
          .insertOnConflictUpdate(
            MedicationsCompanion.insert(
              id: medication.id,
              name: medication.name,
              createdAt: Value(medication.createdAt),
              updatedAt: Value(DateTime.now().toUtc()),
              revision: Value((existing?.revision ?? 0) + 1),
              syncedRevision: Value(existing?.syncedRevision),
            ),
          );
      await SyncTombstoneWriter.clear(_db, SyncCollection.medications, [
        medication.id,
      ]);
    });
  }

  /// Really deletes, leaving tombstones for the medication and every reminder that went with it.
  @override
  Future<void> deleteById(String id) {
    return _db.transaction(() async {
      final List<MedicationReminderRow> reminders = await (_db.select(
        _db.medicationReminders,
      )..where((r) => r.medicationId.equals(id))).get();

      await (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();
      await SyncTombstoneWriter.write(_db, SyncCollection.medications, [id]);
      await SyncTombstoneWriter.write(
        _db,
        SyncCollection.medicationReminders,
        reminders.map((r) => r.id),
      );
    });
  }

  /// GDPR wipe. Tombstones go too: the remote copy is deleted wholesale in the same pass, so there is nothing left to tell the server about.
  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.medications).go();
      await SyncTombstoneWriter.clearAll(_db, SyncCollection.medications);
      await SyncTombstoneWriter.clearAll(
        _db,
        SyncCollection.medicationReminders,
      );
    });
  }
}
