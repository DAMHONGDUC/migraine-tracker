import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/weather/data/repositories/drift_daily_pressure_repository.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:migraine_tracker/features/weather/domain/repositories/weather_repository.dart';
import 'package:migraine_tracker/features/weather/domain/services/daily_pressure_recorder.dart';

/// Stands in for a network failure without dragging dart:io into a test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}

/// Counts fetches, because "at most one per day" is the whole contract: this
/// runs on every launch and every resume.
class _CountingWeather implements WeatherRepository {
  _CountingWeather({this.snapshot, this.throws = false});

  final WeatherSnapshot? snapshot;
  final bool throws;
  int calls = 0;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    calls++;
    // An Exception, not an Error: the real failures here are the network and
    // the platform channel, which is what `on Exception` is scoped to.
    if (throws) throw const SocketExceptionStub();
    return snapshot;
  }

  @override
  Future<PressureForecast?> pressureForecast() async => null;

  // The weather card's payload. No widget test draws it, and no non-UI
  // test needs it, so every fake answers "no weather".
  @override
  Future<WeatherReport?> report() async => null;
}

void main() {
  late AppDatabase db;
  late DriftDailyPressureRepository readings;

  final DateTime today = DateTime(2026, 8, 9, 14);

  WeatherSnapshot snapshot({double delta = -7}) => WeatherSnapshot(
    capturedAt: today,
    pressureHpa: 1004,
    pressureDelta24hHpa: delta,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    readings = DriftDailyPressureRepository(db);
  });

  tearDown(() => db.close());

  test('records the day at local midnight, whatever hour it ran', () async {
    await DailyPressureRecorder(
      readings,
      _CountingWeather(snapshot: snapshot()),
    ).recordToday(now: today);

    final DailyPressure stored = (await readings.since(
      DateTime(2026, 8, 1),
    )).single;

    expect(stored.day, DateTime(2026, 8, 9));
    expect(stored.pressureDelta24hHpa, -7);
    expect(stored.isDrop(5), isTrue);
  });

  // It runs on launch AND resume, so without the guard a day spent opening
  // the app is a day of network calls to overwrite nearly the same number.
  test('fetches at most once a day', () async {
    final _CountingWeather weather = _CountingWeather(snapshot: snapshot());
    final DailyPressureRecorder recorder = DailyPressureRecorder(
      readings,
      weather,
    );

    await recorder.recordToday(now: today);
    await recorder.recordToday(now: today.add(const Duration(hours: 3)));
    await recorder.recordToday(now: today.add(const Duration(hours: 6)));

    expect(weather.calls, 1);
    expect((await readings.since(DateTime(2026, 8, 1))).length, 1);
  });

  test('a new day is a new reading', () async {
    final _CountingWeather weather = _CountingWeather(snapshot: snapshot());
    final DailyPressureRecorder recorder = DailyPressureRecorder(
      readings,
      weather,
    );

    await recorder.recordToday(now: today);
    await recorder.recordToday(now: today.add(const Duration(days: 1)));

    expect(weather.calls, 2);
    expect((await readings.since(DateTime(2026, 8, 1))).length, 2);
  });

  // Offline, or no location. A gap in the sample, never an error to show.
  test('no snapshot means no row and no throw', () async {
    await expectLater(
      DailyPressureRecorder(
        readings,
        _CountingWeather(),
      ).recordToday(now: today),
      completes,
    );

    expect(await readings.since(DateTime(2026, 8, 1)), isEmpty);
  });

  test('a failing fetch is swallowed', () async {
    await expectLater(
      DailyPressureRecorder(
        readings,
        _CountingWeather(throws: true),
      ).recordToday(now: today),
      completes,
    );

    expect(await readings.since(DateTime(2026, 8, 1)), isEmpty);
  });

  group('the store', () {
    test('reads back only from the window asked for', () async {
      await readings.upsert(
        DailyPressure(
          day: DateTime(2026, 8, 1),
          pressureHpa: 1010,
          pressureDelta24hHpa: 1,
        ),
      );
      await readings.upsert(
        DailyPressure(
          day: DateTime(2026, 8, 9),
          pressureHpa: 1004,
          pressureDelta24hHpa: -7,
        ),
      );

      expect(
        (await readings.since(DateTime(2026, 8, 5))).single.day,
        DateTime(2026, 8, 9),
      );
    });

    // Derived from the user's location, so it is theirs and goes with the
    // rest (hard rule 8).
    test('the wipe clears it', () async {
      await readings.upsert(
        DailyPressure(
          day: DateTime(2026, 8, 9),
          pressureHpa: 1004,
          pressureDelta24hHpa: -7,
        ),
      );

      await readings.deleteAll();

      expect(await readings.since(DateTime(2020)), isEmpty);
    });
  });
}
