import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_tracker/features/weather/data/datasources/open_meteo_data_source.dart';

/// Builds an Open-Meteo style hourly payload: [hours] hourly samples ending
/// at [end] (inclusive), pressures supplied oldest-first.
String payload({
  required DateTime end,
  required List<num?> pressures,
  List<num?>? humidities,
  List<num?>? temperatures,
}) {
  final start = end.subtract(Duration(hours: pressures.length - 1));
  final times = [
    for (var i = 0; i < pressures.length; i++)
      start
          .add(Duration(hours: i))
          .toIso8601String()
          .substring(0, 16), // "2026-07-08T13:00" — no seconds, no Z
  ];
  return jsonEncode({
    'hourly': {
      'time': times,
      'surface_pressure': pressures,
      'relative_humidity_2m':
          humidities ?? List<num?>.filled(pressures.length, 70),
      'temperature_2m':
          temperatures ?? List<num?>.filled(pressures.length, 20),
    },
  });
}

void main() {
  final instant = DateTime.utc(2026, 7, 8, 13);

  OpenMeteoDataSource sourceReturning(
    String body, {
    int status = 200,
    void Function(Uri)? onRequest,
  }) {
    return OpenMeteoDataSource(
      MockClient((request) async {
        onRequest?.call(request.url);
        return http.Response(
          body,
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  test('parses the sample at the requested hour and computes the 24h delta',
      () async {
    // 30 samples; last = instant. Pressure fell from 1013 to 1005 over the
    // final 24 hours.
    final pressures = List<num?>.generate(30, (i) => i < 6 ? 1015 : 1013);
    pressures[29] = 1005; // now
    pressures[5] = 1013; // 24h before now

    Uri? requested;
    final source = sourceReturning(
      payload(end: instant, pressures: pressures),
      onRequest: (uri) => requested = uri,
    );

    final snapshot = await source.snapshotAt(
      latitude: 21.03,
      longitude: 105.85,
      instant: instant,
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.pressureHpa, 1005);
    expect(snapshot.pressureDelta24hHpa, 1005 - 1013);
    expect(snapshot.humidityPercent, 70);
    expect(snapshot.temperatureCelsius, 20);
    expect(snapshot.capturedAt, instant);
    expect(requested!.queryParameters['timezone'], 'UTC');
    expect(requested!.queryParameters['past_days'], '7');
  });

  test('returns null when the instant is outside the data window', () async {
    final source = sourceReturning(
      payload(end: instant, pressures: List<num?>.filled(30, 1010)),
    );
    final snapshot = await source.snapshotAt(
      latitude: 0,
      longitude: 0,
      instant: instant.add(const Duration(hours: 6)),
    );
    expect(snapshot, isNull);
  });

  test('returns null when fewer than 24h of history precede the instant',
      () async {
    final source = sourceReturning(
      payload(end: instant, pressures: List<num?>.filled(10, 1010)),
    );
    final snapshot = await source.snapshotAt(
      latitude: 0,
      longitude: 0,
      instant: instant,
    );
    expect(snapshot, isNull);
  });

  test('returns null when the pressure sample is missing (null)', () async {
    final pressures = List<num?>.filled(30, 1010);
    pressures[29] = null;
    final source = sourceReturning(payload(end: instant, pressures: pressures));
    final snapshot = await source.snapshotAt(
      latitude: 0,
      longitude: 0,
      instant: instant,
    );
    expect(snapshot, isNull);
  });

  test('returns null on HTTP errors and malformed bodies', () async {
    expect(
      await sourceReturning('{}', status: 500)
          .snapshotAt(latitude: 0, longitude: 0, instant: instant),
      isNull,
    );
    expect(
      await sourceReturning('not json')
          .snapshotAt(latitude: 0, longitude: 0, instant: instant),
      isNull,
    );
    expect(
      await sourceReturning('{"hourly": null}')
          .snapshotAt(latitude: 0, longitude: 0, instant: instant),
      isNull,
    );
  });

  test('missing humidity/temperature stay null without failing', () async {
    final source = sourceReturning(
      payload(
        end: instant,
        pressures: List<num?>.filled(30, 1010),
        humidities: List<num?>.filled(30, null),
        temperatures: List<num?>.filled(30, null),
      ),
    );
    final snapshot = await source.snapshotAt(
      latitude: 0,
      longitude: 0,
      instant: instant,
    );
    expect(snapshot, isNotNull);
    expect(snapshot!.humidityPercent, isNull);
    expect(snapshot.temperatureCelsius, isNull);
  });
}
