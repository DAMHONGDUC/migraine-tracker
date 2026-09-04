import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_log_repository.dart';
import 'daily_log_mapper.dart';

/// Drift-backed [DailyLogRepository].
class DriftDailyLogRepository implements DailyLogRepository {
  const DriftDailyLogRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DailyLog?> forDay(DateTime day) async {
    final DailyLogRow? row = await _rowFor(DateTimeUtils.dayKey(day));

    return row == null ? null : DailyLogMapper.toDomain(row);
  }

  // - The key is `yyyy-MM-dd`, so a string range IS a date range and no month rolls over wrong.
  @override
  Future<List<DailyLog>> range(DateTime from, DateTime to) async {
    final String start = DateTimeUtils.dayKey(from);
    final String end = DateTimeUtils.dayKey(to);
    final List<DailyLogRow> rows =
        await (_db.select(_db.dailyLogs)
              ..where((l) => l.id.isBiggerOrEqualValue(start))
              ..where((l) => l.id.isSmallerOrEqualValue(end))
              ..orderBy([(l) => OrderingTerm.asc(l.id)]))
            .get();

    return rows.map(DailyLogMapper.toDomain).toList();
  }

  @override
  Stream<DailyLog?> watchDay(DateTime day) {
    final String key = DateTimeUtils.dayKey(day);

    return (_db.select(
      _db.dailyLogs,
    )..where((l) => l.id.equals(key))).watchSingleOrNull().map(
      (row) => row == null ? null : DailyLogMapper.toDomain(row),
    );
  }

  @override
  Future<void> save(DailyLog log) {
    return _db.transaction(() async {
      final String key = DateTimeUtils.dayKey(log.day);
      final DailyLogRow? existing = await _rowFor(key);

      await _db
          .into(_db.dailyLogs)
          .insertOnConflictUpdate(
            DailyLogsCompanion.insert(
              id: key,
              sleepQuality: Value(log.sleepQuality),
              stressLevel: Value(log.stressLevel),
              factors: Value(log.factors),
              steps: Value(log.steps),
              updatedAt: Value(DateTime.now().toUtc()),
              revision: Value((existing?.revision ?? 0) + 1),
              syncedRevision: Value(existing?.syncedRevision),
            ),
          );
      // A day the user re-answers after deleting it would otherwise be deleted again by its own stale tombstone.
      await SyncTombstoneWriter.clear(_db, SyncCollection.dailyLogs, [key]);
    });
  }

  // - Counts what the user answered, never what Health filled in on its own: a row of sleep minutes is not a check-in.
  @override
  Future<int> answeredCount() async {
    final List<DailyLogRow> rows = await _db.select(_db.dailyLogs).get();

    return rows.where((row) => DailyLogMapper.toDomain(row).isAnswered).length;
  }

  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.dailyLogs).go();
      await SyncTombstoneWriter.clearAll(_db, SyncCollection.dailyLogs);
    });
  }

  Future<DailyLogRow?> _rowFor(String key) => (_db.select(
    _db.dailyLogs,
  )..where((l) => l.id.equals(key))).getSingleOrNull();
}
