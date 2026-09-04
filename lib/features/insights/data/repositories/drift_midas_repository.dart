import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../domain/entities/midas_score.dart';
import '../../domain/repositories/midas_repository.dart';
import 'midas_mapper.dart';

/// Drift-backed [MidasRepository].
class DriftMidasRepository implements MidasRepository {
  const DriftMidasRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<MidasEntry>> watchAll() {
    final query = _db.select(_db.midasEntries)
      ..orderBy([(m) => OrderingTerm.desc(m.takenAt)]);

    return query.watch().map(
      (List<MidasRow> rows) => rows.map(MidasMapper.toDomain).toList(),
    );
  }

  @override
  Future<MidasEntry?> latest() async {
    final MidasRow? row =
        await (_db.select(_db.midasEntries)
              ..orderBy([(m) => OrderingTerm.desc(m.takenAt)])
              ..limit(1))
            .getSingleOrNull();

    return row == null ? null : MidasMapper.toDomain(row);
  }

  @override
  Future<void> upsert(MidasEntry entry) {
    return _db.transaction(() async {
      final MidasRow? existing = await (_db.select(
        _db.midasEntries,
      )..where((m) => m.id.equals(entry.id))).getSingleOrNull();

      await _db
          .into(_db.midasEntries)
          .insertOnConflictUpdate(
            MidasEntriesCompanion.insert(
              id: entry.id,
              takenAt: entry.takenAt,
              missedWorkDays: entry.missedWorkDays,
              reducedWorkDays: entry.reducedWorkDays,
              missedHouseholdDays: entry.missedHouseholdDays,
              reducedHouseholdDays: entry.reducedHouseholdDays,
              missedSocialDays: entry.missedSocialDays,
              updatedAt: Value(DateTime.now().toUtc()),
              revision: Value((existing?.revision ?? 0) + 1),
              syncedRevision: Value(existing?.syncedRevision),
            ),
          );
      await SyncTombstoneWriter.clear(_db, SyncCollection.midas, [entry.id]);
    });
  }

  @override
  Future<void> deleteById(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.midasEntries)..where((m) => m.id.equals(id))).go();
      await SyncTombstoneWriter.write(_db, SyncCollection.midas, [id]);
    });
  }

  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.midasEntries).go();
      await SyncTombstoneWriter.clearAll(_db, SyncCollection.midas);
    });
  }
}
