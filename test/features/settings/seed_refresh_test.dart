import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/providers.dart';
import 'package:migraine_tracker/features/settings/domain/services/dev_seed_service.dart';
import 'package:migraine_tracker/features/settings/providers.dart';
import 'package:migraine_tracker/features/weather/data/repositories/drift_daily_pressure_repository.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

/// Writes one row into each table the one-shot providers read, and nothing else — the real seeder's counts are pinned in `dev_seed_service_test.dart`.
class _OneRowSeeder implements DevSeedService {
  const _OneRowSeeder(this._db);

  final AppDatabase _db;

  @override
  Future<void> seed() async {
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(today.year, today.month, today.day);

    await DriftDailyLogRepository(
      _db,
    ).save(DailyLog(day: day, sleepQuality: 3, stressLevel: 2));
    await DriftDailyPressureRepository(_db).upsert(
      DailyPressure(day: day, pressureHpa: 1013, pressureDelta24hHpa: -6),
    );
  }
}

/// The check-ins and the pressure history are read once, not watched, so only an invalidation puts seeded rows on screen before the next launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeding refreshes the providers that do not watch the tables', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final ProviderContainer container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        devSeedServiceProvider.overrideWithValue(_OneRowSeeder(db)),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    // Read BEFORE the seed: this is what caches the empty answer the bug then kept showing.
    expect(await container.read(recentDailyLogsProvider.future), isEmpty);
    expect(await container.read(answeredDailyLogCountProvider.future), 0);
    expect(await container.read(dailyPressureHistoryProvider.future), isEmpty);

    await container.read(settingsControllerProvider).seedDevData();

    expect(await container.read(recentDailyLogsProvider.future), hasLength(1));
    expect(await container.read(answeredDailyLogCountProvider.future), 1);
    expect(
      await container.read(dailyPressureHistoryProvider.future),
      hasLength(1),
    );
  });
}
