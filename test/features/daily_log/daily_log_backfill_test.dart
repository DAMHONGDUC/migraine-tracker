import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/daily_log_backfill_constant.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/utils/date_time_utils.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';

/// A day lost to an attack is answerable the morning after — but only for three days.
void main() {
  group('the backfill window', () {
    test('a missing key is today', () {
      expect(
        DateTimeUtils.dayKey(DailyLogBackfillConstant.resolve(null)),
        DateTimeUtils.dayKey(DateTime.now()),
      );
    });

    test('yesterday resolves to yesterday', () {
      final DateTime yesterday = DateTime.now().subtract(
        const Duration(days: 1),
      );

      expect(
        DateTimeUtils.dayKey(
          DailyLogBackfillConstant.resolve(DateTimeUtils.dayKey(yesterday)),
        ),
        DateTimeUtils.dayKey(yesterday),
      );
    });

    test('past the window falls back to today, never to the asked day', () {
      final DateTime tooOld = DateTime.now().subtract(
        Duration(days: DailyLogBackfillConstant.days + 1),
      );

      expect(
        DateTimeUtils.dayKey(
          DailyLogBackfillConstant.resolve(DateTimeUtils.dayKey(tooOld)),
        ),
        DateTimeUtils.dayKey(DateTime.now()),
      );
    });

    test('a future day is refused too', () {
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(
        DateTimeUtils.dayKey(
          DailyLogBackfillConstant.resolve(DateTimeUtils.dayKey(tomorrow)),
        ),
        DateTimeUtils.dayKey(DateTime.now()),
      );
    });

    test('nonsense resolves to today rather than throwing', () {
      expect(
        DateTimeUtils.dayKey(DailyLogBackfillConstant.resolve('not-a-day')),
        DateTimeUtils.dayKey(DateTime.now()),
      );
    });
  });

  group('a trigger feeding the day', () {
    late AppDatabase db;
    late DriftDailyLogRepository logs;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      logs = DriftDailyLogRepository(db);
    });

    tearDown(() async => db.close());

    test('writes the factor onto a day that had no row at all', () async {
      final DateTime day = DateTime(2026, 7, 1);

      await logs.addFactorsToDay(day, <DailyFactor>[DailyFactor.alcohol]);

      expect((await logs.forDay(day))!.factors, <DailyFactor>[
        DailyFactor.alcohol,
      ]);
    });

    test('keeps the answers already on the row', () async {
      final DateTime day = DateTime(2026, 7, 1);
      await logs.save(
        DailyLog(
          day: day,
          sleepQuality: 2,
          factors: const <DailyFactor>[DailyFactor.caffeine],
        ),
      );

      await logs.addFactorsToDay(day, <DailyFactor>[DailyFactor.alcohol]);

      final DailyLog stored = (await logs.forDay(day))!;
      expect(stored.sleepQuality, 2);
      expect(
        stored.factors,
        containsAll(<DailyFactor>[DailyFactor.caffeine, DailyFactor.alcohol]),
      );
    });

    test('a factor already on the day is not written twice', () async {
      final DateTime day = DateTime(2026, 7, 1);
      await logs.save(
        DailyLog(day: day, factors: const <DailyFactor>[DailyFactor.alcohol]),
      );

      await logs.addFactorsToDay(day, <DailyFactor>[DailyFactor.alcohol]);

      expect((await logs.forDay(day))!.factors, hasLength(1));
    });
  });
}
