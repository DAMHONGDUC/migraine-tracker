import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/domain/services/weather_attach_service.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';

/// Records requested instants; returns snapshots from [byInstant].
class RecordingWeatherRepository implements WeatherRepository {
  RecordingWeatherRepository(this.byInstant);

  final Map<DateTime, WeatherSnapshot?> byInstant;
  final List<DateTime> requests = [];

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    requests.add(instant);
    return byInstant[instant];
  }

  @override
  Future<PressureForecast?> pressureForecast() async => null;
}

void main() {
  late AppDatabase db;
  late DriftAttackRepository attacks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attacks = DriftAttackRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Attack attack(String id, DateTime startedAt) => Attack(
    id: id,
    startedAt: startedAt,
    intensity: 5,
    location: HeadLocation.left,
  );

  WeatherSnapshot snapshot(DateTime at, {double delta = -6}) =>
      WeatherSnapshot(
        capturedAt: at,
        pressureHpa: 1008,
        pressureDelta24hHpa: delta,
      );

  test('onAttackLogged attaches weather and backfills older attacks', () async {
    final oldTime = DateTime.utc(2026, 7, 5, 9);
    final newTime = DateTime.utc(2026, 7, 8, 13);
    await attacks.insert(attack('old', oldTime));
    await attacks.insert(attack('new', newTime));

    final weather = RecordingWeatherRepository({
      newTime: snapshot(newTime, delta: -8),
      oldTime: snapshot(oldTime, delta: -3),
    });
    final service = WeatherAttachService(attacks, weather);

    await service.onAttackLogged(attack('new', newTime));

    final all = await attacks.watchAll().first;
    final byId = {for (final a in all) a.id: a};
    expect(byId['new']!.weather?.pressureDelta24hHpa, -8);
    expect(
      byId['old']!.weather?.pressureDelta24hHpa,
      -3,
      reason: 'backfill must use the OLD attack start time, not now',
    );
  });

  test('offline (null snapshot) leaves the attack in the backfill queue',
      () async {
    final when = DateTime.utc(2026, 7, 8, 13);
    await attacks.insert(attack('a1', when));

    final weather = RecordingWeatherRepository({when: null});
    final service = WeatherAttachService(attacks, weather);

    await service.onAttackLogged(attack('a1', when));

    expect(
      (await attacks.attacksMissingWeather()).map((a) => a.id),
      ['a1'],
    );
  });

  test('backfillMissing skips attacks whose weather is unavailable', () async {
    final okTime = DateTime.utc(2026, 7, 7, 10);
    final tooOldTime = DateTime.utc(2026, 5, 1, 10);
    await attacks.insert(attack('ok', okTime));
    await attacks.insert(attack('too-old', tooOldTime));

    final weather = RecordingWeatherRepository({
      okTime: snapshot(okTime),
      tooOldTime: null, // outside the provider's 7-day window
    });
    await WeatherAttachService(attacks, weather).backfillMissing();

    expect(
      (await attacks.attacksMissingWeather()).map((a) => a.id),
      ['too-old'],
    );
    expect(weather.requests, containsAll([okTime, tooOldTime]));
  });

  test('backfillMissing is a no-op when nothing is missing', () async {
    final weather = RecordingWeatherRepository({});
    await WeatherAttachService(attacks, weather).backfillMissing();
    expect(weather.requests, isEmpty);
  });
}
