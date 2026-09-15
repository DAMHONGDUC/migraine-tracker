import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/services/weather_attach_service.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';

/// Answers for one instant only, and records every instant it was asked about.
class _Weather implements WeatherRepository {
  _Weather(this.answersFor);

  final DateTime answersFor;
  final List<DateTime> requests = <DateTime>[];

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    requests.add(instant);

    return instant == answersFor ? _snapshotAt(instant) : null;
  }

  @override
  Future<PressureForecast?> pressureForecast() async => null;

  @override
  Future<WeatherReport?> report() async => null;
}

WeatherSnapshot _snapshotAt(DateTime instant) => WeatherSnapshot(
  capturedAt: instant,
  pressureHpa: 1008.2,
  pressureDelta24hHpa: -6,
);

/// Correcting when an attack started is the one edit that invalidates the reading attached to it.
void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
  });

  tearDown(() async => db.close());

  final DateTime loggedAt = DateTime.utc(2026, 7, 1, 9);
  final DateTime actuallyStarted = DateTime.utc(2026, 7, 1, 3);

  Attack attack() => Attack(
    id: 'a1',
    startedAt: loggedAt,
    intensity: 8,
    regions: const <HeadRegion>[HeadRegion.templeL],
  );

  test(
    'the new start time replaces the old one and bumps the revision',
    () async {
      await attacks.insert(attack());
      // The revision is a sync column, so it is read off the row rather than the entity.
      final int before = (await db.select(db.attacks).getSingle()).revision;

      await attacks.updateStartedAt('a1', actuallyStarted);

      expect(
        (await attacks.watchAll().first).single.startedAt,
        actuallyStarted,
      );
      expect(
        (await db.select(db.attacks).getSingle()).revision,
        greaterThan(before),
      );
    },
  );

  test(
    'the snapshot taken for the old instant does not survive the edit',
    () async {
      await attacks.insert(attack());
      // Whatever was attached for 09:00 belonged to 09:00.
      await attacks.attachWeather('a1', _snapshotAt(loggedAt));
      expect((await attacks.watchAll().first).single.weather, isNotNull);

      await attacks.updateStartedAt('a1', actuallyStarted);

      final Attack stored = (await attacks.watchAll().first).single;
      expect(stored.weather, isNull);
      // And the attack is back in the queue the backfill walks.
      expect(await attacks.attacksMissingWeather(), hasLength(1));
    },
  );

  test('re-attaching asks for the new instant, never the old one', () async {
    await attacks.insert(attack());
    await attacks.updateStartedAt('a1', actuallyStarted);

    final _Weather weather = _Weather(actuallyStarted);
    await WeatherAttachService(
      attacks,
      weather,
    ).onStartedAtChanged('a1', actuallyStarted);

    expect(weather.requests, contains(actuallyStarted));
    expect(weather.requests, isNot(contains(loggedAt)));
    expect(
      (await attacks.watchAll().first).single.weather?.capturedAt,
      actuallyStarted,
    );
  });
}
