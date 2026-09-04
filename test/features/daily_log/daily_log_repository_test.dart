import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';

void main() {
  late AppDatabase db;
  late DriftDailyLogRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftDailyLogRepository(db);
  });

  tearDown(() => db.close());

  test('a saved day comes back whole', () async {
    await repository.save(
      DailyLog(
        day: DateTime(2026, 9, 14, 21, 30),
        sleepQuality: 2,
        stressLevel: 5,
        factors: const <DailyFactor>[DailyFactor.alcohol],
        steps: 4200,
      ),
    );

    final DailyLog? stored = await repository.forDay(DateTime(2026, 9, 14, 7));

    expect(stored, isNotNull);
    expect(stored!.day, DateTime(2026, 9, 14));
    expect(stored.sleepQuality, 2);
    expect(stored.stressLevel, 5);
    expect(stored.factors, const <DailyFactor>[DailyFactor.alcohol]);
    expect(stored.steps, 4200);
  });

  // The day is the primary key, so answering the same day twice edits it — which is also what makes two devices' Tuesday one record.
  test('saving the same day again replaces it', () async {
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 1),
    );
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 5),
    );

    final List<DailyLog> all = await repository.range(
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 30),
    );

    expect(all, hasLength(1));
    expect(all.single.sleepQuality, 5);
  });

  // The key is `yyyy-MM-dd`, so a string range has to behave as a date range across a month boundary.
  test('a range spanning a month boundary returns the days in order', () async {
    for (final DateTime day in <DateTime>[
      DateTime(2026, 8, 30),
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
    ]) {
      await repository.save(DailyLog(day: day, stressLevel: 3));
    }

    final List<DailyLog> range = await repository.range(
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 1),
    );

    expect(range.map((DailyLog log) => log.day), <DateTime>[
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 1),
    ]);
  });

  // A row Health filled in on its own is not a check-in, and the trigger map counts check-ins.
  test('answeredCount ignores a row holding only a step count', () async {
    await repository.save(DailyLog(day: DateTime(2026, 9, 13), steps: 900));
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 3),
    );

    expect(await repository.answeredCount(), 1);
  });

  test('watchDay emits the day as it is written', () async {
    final Future<DailyLog?> answered = repository
        .watchDay(DateTime(2026, 9, 14))
        .firstWhere((DailyLog? log) => log != null);

    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), stressLevel: 4),
    );

    expect((await answered)!.stressLevel, 4);
  });

  test('deleteAll leaves nothing and tombstones nothing behind', () async {
    await repository.save(
      DailyLog(day: DateTime(2026, 9, 14), sleepQuality: 3),
    );
    await repository.deleteAll();

    expect(await repository.answeredCount(), 0);
    expect(await db.select(db.syncTombstones).get(), isEmpty);
  });
}
