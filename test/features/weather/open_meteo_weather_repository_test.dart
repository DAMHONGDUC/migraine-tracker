import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/weather/data/datasources/location_source.dart';
import 'package:migraine_tracker/features/weather/data/datasources/open_meteo_data_source.dart';
import 'package:migraine_tracker/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:migraine_tracker/features/weather/domain/entities/geo_point.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

/// Location off / permission denied is the null case the repository has to
/// absorb — hard rule 4 says logging an attack never waits on weather.
class _FakeLocationSource implements LocationSource {
  _FakeLocationSource(this.point);

  final GeoPoint? point;
  int calls = 0;

  @override
  Future<GeoPoint?> currentPosition() async {
    calls++;
    return point;
  }
}

/// Stands in for the HTTP datasource: records the coordinates it was handed,
/// so a test can prove the repository passed the device's own position on.
class _FakeDataSource implements OpenMeteoDataSource {
  _FakeDataSource({this.snapshot, this.series});

  final WeatherSnapshot? snapshot;
  final List<PressurePoint>? series;
  final List<(double, double)> requestedPoints = <(double, double)>[];
  DateTime? requestedInstant;
  DateTime? requestedNow;
  int calls = 0;

  @override
  Future<WeatherSnapshot?> snapshotAt({
    required double latitude,
    required double longitude,
    required DateTime instant,
  }) async {
    calls++;
    requestedPoints.add((latitude, longitude));
    requestedInstant = instant;
    return snapshot;
  }

  @override
  Future<List<PressurePoint>?> pressureSeries({
    required double latitude,
    required double longitude,
    required DateTime now,
  }) async {
    calls++;
    requestedPoints.add((latitude, longitude));
    requestedNow = now;
    return series;
  }
}

void main() {
  const GeoPoint hanoi = GeoPoint(latitude: 21.03, longitude: 105.85);
  final DateTime instant = DateTime.utc(2026, 7, 8, 13);

  group('snapshotAt', () {
    test('passes the device position and instant through', () async {
      final WeatherSnapshot expected = WeatherSnapshot(
        capturedAt: instant,
        pressureHpa: 1005,
        pressureDelta24hHpa: -8,
      );
      final _FakeDataSource source = _FakeDataSource(snapshot: expected);

      final WeatherSnapshot? result = await OpenMeteoWeatherRepository(
        _FakeLocationSource(hanoi),
        source,
      ).snapshotAt(instant);

      expect(result, same(expected));
      expect(source.requestedPoints, <(double, double)>[(21.03, 105.85)]);
      expect(source.requestedInstant, instant);
    });

    // No position means no request at all: an attack logged offline is saved
    // without weather and backfilled later.
    test(
      'returns null without calling the network when location is unavailable',
      () async {
        final _FakeDataSource source = _FakeDataSource();

        final WeatherSnapshot? result = await OpenMeteoWeatherRepository(
          _FakeLocationSource(null),
          source,
        ).snapshotAt(instant);

        expect(result, isNull);
        expect(source.calls, 0);
      },
    );

    test('passes a null datasource answer straight back', () async {
      final WeatherSnapshot? result = await OpenMeteoWeatherRepository(
        _FakeLocationSource(hanoi),
        _FakeDataSource(),
      ).snapshotAt(instant);

      expect(result, isNull);
    });
  });

  group('pressureForecast', () {
    test('wraps the series and stamps generatedAt in UTC', () async {
      final List<PressurePoint> points = <PressurePoint>[
        PressurePoint(time: instant, pressureHpa: 1010),
        PressurePoint(
          time: instant.add(const Duration(hours: 1)),
          pressureHpa: 1009,
        ),
      ];
      final _FakeDataSource source = _FakeDataSource(series: points);

      final PressureForecast? forecast = await OpenMeteoWeatherRepository(
        _FakeLocationSource(hanoi),
        source,
      ).pressureForecast();

      expect(forecast, isNotNull);
      expect(forecast!.points, same(points));
      expect(forecast.generatedAt.isUtc, isTrue);
      // The chart's "now" marker and the window the datasource cut are the
      // same instant, or the marker lands off the series.
      expect(forecast.generatedAt, source.requestedNow);
      expect(source.requestedPoints, <(double, double)>[(21.03, 105.85)]);
    });

    test(
      'returns null without calling the network when location is unavailable',
      () async {
        final _FakeDataSource source = _FakeDataSource();

        final PressureForecast? forecast = await OpenMeteoWeatherRepository(
          _FakeLocationSource(null),
          source,
        ).pressureForecast();

        expect(forecast, isNull);
        expect(source.calls, 0);
      },
    );

    // A failed fetch must not become an empty chart — the card has to be able
    // to tell "no data" from "flat pressure".
    test(
      'returns null when the series is null, never an empty forecast',
      () async {
        final PressureForecast? forecast = await OpenMeteoWeatherRepository(
          _FakeLocationSource(hanoi),
          _FakeDataSource(),
        ).pressureForecast();

        expect(forecast, isNull);
      },
    );
  });
}
