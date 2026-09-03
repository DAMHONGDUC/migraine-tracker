import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/daily_log.dart';
import 'daily_log_mapper.dart';

/// The daily check-in side of sync.
class DriftDailyLogSyncStore extends DriftSyncLocalStore<DailyLog> {
  const DriftDailyLogSyncStore(super.db);

  /// A row written before the first push has no `updatedAt`; nothing here is older than this, so it can never hide a change.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  @override
  SyncCollection get collection => SyncCollection.dailyLogs;

  /// The day itself is the id, which is what makes two devices' Tuesday one record rather than two.
  @override
  String idOf(DailyLog value) => DateTimeUtils.dayKey(value.day);

  @override
  Future<List<SyncRecord<DailyLog>>> loadDirty() async {
    final List<DailyLogRow> rows =
        await (db.select(db.dailyLogs)..where(
              (l) =>
                  l.syncedRevision.isNull() |
                  l.syncedRevision.isNotExp(l.revision),
            ))
            .get();

    return rows
        .map(
          (row) => SyncRecord<DailyLog>(
            id: row.id,
            updatedAt: (row.updatedAt ?? _beginning).toUtc(),
            revision: row.revision,
            value: DailyLogMapper.toDomain(row),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> localUpdatedAt(String id) async {
    final DailyLogRow? row = await _row(id);

    return row == null ? null : (row.updatedAt ?? _beginning).toUtc();
  }

  @override
  Future<int> nextRevision(String id) async =>
      ((await _row(id))?.revision ?? 0) + 1;

  @override
  Future<bool> writeFromRemote(
    DailyLog value,
    DateTime updatedAt,
    int revision,
  ) async {
    await db
        .into(db.dailyLogs)
        .insertOnConflictUpdate(
          DailyLogsCompanion.insert(
            id: idOf(value),
            sleepQuality: Value(value.sleepQuality),
            stressLevel: Value(value.stressLevel),
            factors: Value(value.factors),
            steps: Value(value.steps),
            updatedAt: Value(updatedAt),
            revision: Value(revision),
            syncedRevision: Value(revision),
          ),
        );
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.dailyLogs)..where((l) => l.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    await (db.update(db.dailyLogs)
          ..where((l) => l.id.equals(id) & l.revision.equals(revision)))
        .write(DailyLogsCompanion(syncedRevision: Value(revision)));
  }

  Future<DailyLogRow?> _row(String id) => (db.select(
    db.dailyLogs,
  )..where((l) => l.id.equals(id))).getSingleOrNull();
}
