import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/medication.dart';

/// The medications side of sync.
class DriftMedicationSyncStore extends DriftSyncLocalStore<Medication> {
  const DriftMedicationSyncStore(super.db);

  @override
  SyncCollection get collection => SyncCollection.medications;

  @override
  String idOf(Medication value) => value.id;

  @override
  Future<List<SyncRecord<Medication>>> loadDirty() async {
    final List<MedicationRow> rows =
        await (db.select(db.medications)..where(
              (m) =>
                  m.syncedRevision.isNull() |
                  m.syncedRevision.isNotExp(m.revision),
            ))
            .get();

    return rows
        .map(
          (row) => SyncRecord<Medication>(
            id: row.id,
            updatedAt: _effectiveUpdatedAt(row),
            revision: row.revision,
            value: Medication(
              id: row.id,
              name: row.name,
              createdAt: row.createdAt,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> localUpdatedAt(String id) async {
    final MedicationRow? row = await _row(id);

    return row == null ? null : _effectiveUpdatedAt(row);
  }

  @override
  Future<int> nextRevision(String id) async =>
      ((await _row(id))?.revision ?? 0) + 1;

  @override
  Future<bool> writeFromRemote(
    Medication value,
    DateTime updatedAt,
    int revision,
  ) async {
    await db
        .into(db.medications)
        .insertOnConflictUpdate(
          MedicationsCompanion.insert(
            id: value.id,
            name: value.name,
            createdAt: Value(value.createdAt),
            updatedAt: Value(updatedAt),
            revision: Value(revision),
            syncedRevision: Value(revision),
          ),
        );
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.medications)..where((m) => m.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    await (db.update(db.medications)
          ..where((m) => m.id.equals(id) & m.revision.equals(revision)))
        .write(MedicationsCompanion(syncedRevision: Value(revision)));
  }

  Future<MedicationRow?> _row(String id) => (db.select(
    db.medications,
  )..where((m) => m.id.equals(id))).getSingleOrNull();

  /// Rows saved before v7 have no `updatedAt`.
  DateTime _effectiveUpdatedAt(MedicationRow row) =>
      (row.updatedAt ?? row.createdAt ?? _beginning).toUtc();

  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
}
