import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAttackRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  WeatherSnapshot snapshot({double delta = -6.0}) => WeatherSnapshot(
    capturedAt: DateTime.utc(2026, 7, 1, 8),
    pressureHpa: 1008.2,
    pressureDelta24hHpa: delta,
    humidityPercent: 71.5,
    temperatureCelsius: 19.3,
  );

  Attack fullAttack() => Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 8, 30),
    intensity: 7,
    location: HeadLocation.right,
    medicationName: 'Sumatriptan',
    symptoms: const ['aura', 'nausea'],
    triggers: const ['stress'],
    notes: 'woke up with it',
    weather: snapshot(),
  );

  test('insert and read back a full attack preserves every field', () async {
    await repository.insert(fullAttack());

    final attacks = await repository.watchAll().first;
    expect(attacks, hasLength(1));
    final a = attacks.single;
    expect(a.id, 'a1');
    expect(a.startedAt, DateTime.utc(2026, 7, 1, 8, 30));
    expect(a.startedAt.isUtc, isTrue);
    expect(a.intensity, 7);
    expect(a.location, HeadLocation.right);
    expect(a.medicationName, 'Sumatriptan');
    expect(a.symptoms, ['aura', 'nausea']);
    expect(a.triggers, ['stress']);
    expect(a.notes, 'woke up with it');
    expect(a.weather, snapshot());
  });

  test('offline attack has no weather and shows up in the backfill queue',
      () async {
    final offline = Attack(
      id: 'a2',
      startedAt: DateTime.utc(2026, 7, 2),
      intensity: 4,
      location: HeadLocation.front,
    );
    await repository.insert(offline);

    final missing = await repository.attacksMissingWeather();
    expect(missing.map((a) => a.id), ['a2']);

    await repository.attachWeather('a2', snapshot(delta: -8));

    expect(await repository.attacksMissingWeather(), isEmpty);
    final attacks = await repository.watchAll().first;
    expect(attacks.single.weather?.pressureDelta24hHpa, -8);
  });

  test('watchAll returns attacks newest first', () async {
    for (final (i, day) in [3, 1, 2].indexed) {
      await repository.insert(
        Attack(
          id: 'a$i',
          startedAt: DateTime.utc(2026, 7, day),
          intensity: 5,
          location: HeadLocation.whole,
        ),
      );
    }

    final attacks = await repository.watchAll().first;
    expect(attacks.map((a) => a.startedAt.day), [3, 2, 1]);
  });

  test('attachWeather twice keeps the latest snapshot', () async {
    await repository.insert(fullAttack());
    await repository.attachWeather('a1', snapshot(delta: -12));

    final attacks = await repository.watchAll().first;
    expect(attacks.single.weather?.pressureDelta24hHpa, -12);
  });

  test('updateDetails fills in the optional fields after the 3-tap save',
      () async {
    final bare = Attack(
      id: 'a3',
      startedAt: DateTime.utc(2026, 7, 3),
      intensity: 6,
      location: HeadLocation.back,
    );
    await repository.insert(bare);

    await repository.updateDetails(
      'a3',
      symptoms: ['aura'],
      triggers: ['dehydration', 'heat'],
      notes: 'started at work',
    );

    final attack = (await repository.watchAll().first).single;
    expect(attack.symptoms, ['aura']);
    expect(attack.triggers, ['dehydration', 'heat']);
    expect(attack.notes, 'started at work');
    expect(attack.intensity, 6, reason: 'tap-flow fields must be untouched');
  });

  test('deleteAll wipes attacks and cascades to weather snapshots', () async {
    await repository.insert(fullAttack());
    await repository.deleteAll();

    expect(await repository.watchAll().first, isEmpty);
    final orphanedWeather = await db.select(db.weatherSnapshots).get();
    expect(orphanedWeather, isEmpty);
  });

  test('weather rows cannot exist without a matching attack', () async {
    expect(
      () => repository.attachWeather('ghost', snapshot()),
      throwsA(isA<SqliteException>()),
    );
  });
}
