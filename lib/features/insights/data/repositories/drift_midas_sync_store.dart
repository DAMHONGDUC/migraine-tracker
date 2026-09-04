import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/midas_score.dart';
import 'midas_mapper.dart';

/// The MIDAS side of sync.
class DriftMidasSyncStore extends DriftSyncLocalStore<MidasEntry> {
  const DriftMidasSyncStore(super.db);

  /// A row written before the first push has no `updatedAt`; nothing is older than this, so it can never hide a change.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  @override
  SyncCollection get collection => SyncCollection.midas;

  @override
  String idOf(MidasEntry value) => value.id;

  @override
  Future<List<SyncRecord<MidasEntry>>> loadDirty() async {
    final List<MidasRow> rows =
        await (db.select(db.midasEntries)..where(
              (m) =>
                  m.syncedRevision.isNull() |
                  m.syncedRevision.isNotExp(m.revision),
            ))
            .get();

    return rows
        .map(
          (MidasRow row) => SyncRecord<MidasEntry>(
            id: row.id,
            updatedAt: (row.updatedAt ?? _beginning).toUtc(),
            revision: row.revision,
            value: MidasMapper.toDomain(row),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> localUpdatedAt(String id) async {
    final MidasRow? row = await _row(id);

    return row == null ? null : (row.updatedAt ?? _beginning).toUtc();
  }

  @override
  Future<int> nextRevision(String id) async =>
      ((await _row(id))?.revision ?? 0) + 1;

  @override
  Future<bool> writeFromRemote(
    MidasEntry value,
    DateTime updatedAt,
    int revision,
  ) async {
    await db
        .into(db.midasEntries)
        .insertOnConflictUpdate(
          MidasEntriesCompanion.insert(
            id: value.id,
            takenAt: value.takenAt,
            missedWorkDays: value.missedWorkDays,
            reducedWorkDays: value.reducedWorkDays,
            missedHouseholdDays: value.missedHouseholdDays,
            reducedHouseholdDays: value.reducedHouseholdDays,
            missedSocialDays: value.missedSocialDays,
            updatedAt: Value(updatedAt),
            revision: Value(revision),
            syncedRevision: Value(revision),
          ),
        );
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.midasEntries)..where((m) => m.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    await (db.update(db.midasEntries)
          ..where((m) => m.id.equals(id) & m.revision.equals(revision)))
        .write(MidasEntriesCompanion(syncedRevision: Value(revision)));
  }

  Future<MidasRow?> _row(String id) => (db.select(
    db.midasEntries,
  )..where((m) => m.id.equals(id))).getSingleOrNull();
}
