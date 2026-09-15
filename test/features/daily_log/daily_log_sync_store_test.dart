import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_sync_store.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_record.dart';

void main() {
  late AppDatabase db;
  late DriftDailyLogRepository repository;
  late DriftDailyLogSyncStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftDailyLogRepository(db);
    store = DriftDailyLogSyncStore(db);
  });

  tearDown(() => db.close());

  test('it syncs under its own collection name', () {
    expect(store.collection, SyncCollection.dailyLogs);
    expect(SyncCollection.dailyLogs.name, 'daily_logs');
  });

  test(
    'a saved day is pending until the server confirms its revision',
    () async {
      await repository.save(
        DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 3),
      );

      final List<SyncRecord<DailyLog>> pending = await store.pendingChanges();

      expect(pending, hasLength(1));
      expect(pending.single.id, '2026-09-14');

      await store.markSynced(pending.single.id, pending.single.revision);

      expect(await store.pendingChanges(), isEmpty);
    },
  );

  // The day is the id, so the same Tuesday from another device edits this one's row instead of arriving as a second Tuesday.
  test('a remote day lands on the row the device already has', () async {
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 1),
    );

    final bool applied = await store.applyRemote(
      DailyLog(
        day: DateTime(2026, 9, 14),
        sleepQuality: 5,
        factors: const <DailyFactor>[DailyFactor.travel],
      ),
      DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );

    expect(applied, isTrue);

    final List<DailyLog> all = await repository.range(
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 30),
    );

    expect(all, hasLength(1));
    expect(all.single.sleepQuality, 5);
    expect(all.single.factors, const <DailyFactor>[DailyFactor.travel]);
  });

  test('a remote day older than the local one is refused', () async {
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 1),
    );

    final bool applied = await store.applyRemote(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 5),
      DateTime.utc(2020),
    );

    expect(applied, isFalse);
    expect((await repository.forDay(DateTime(2026, 9, 14)))!.sleepQuality, 1);
  });

  // Marking a record synced writes to its own table, and that write must not read as a fresh local edit.
  test('a pulled day is not immediately pending again', () async {
    await store.applyRemote(
      DailyLog(day: DateTime(2026, 9, 14), stressLevel: 2),
      DateTime.now().toUtc(),
    );

    expect(await store.pendingChanges(), isEmpty);
  });
}
