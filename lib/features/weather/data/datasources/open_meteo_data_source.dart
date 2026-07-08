import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/weather_snapshot.dart';

/// Fetches hourly pressure/humidity/temperature from Open-Meteo.
///
/// Temporary in-app source until the WeatherKit key is configured (see
/// CLAUDE.md); the backend cron uses Open-Meteo permanently. `past_days=7`
/// lets offline attacks from up to a week ago be backfilled with the
/// weather *at their start time*, not today's.
class OpenMeteoDataSource {
  const OpenMeteoDataSource(this._client);

  final http.Client _client;

  static const _host = 'api.open-meteo.com';

  /// Nearest hourly sample to the target instant must be within this.
  static const _tolerance = Duration(minutes: 90);

  Future<WeatherSnapshot?> snapshotAt({
    required double latitude,
    required double longitude,
    required DateTime instant,
  }) async {
    try {
      final uri = Uri.https(_host, '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'hourly': 'surface_pressure,relative_humidity_2m,temperature_2m',
        'past_days': '7',
        'forecast_days': '1',
        'timezone': 'UTC',
      });
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = body['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return null;

      final times = (hourly['time'] as List<Object?>)
          .cast<String>()
          // timezone=UTC returns naive timestamps; mark them as UTC.
          .map((t) => DateTime.parse('${t}Z'))
          .toList();
      final pressures = (hourly['surface_pressure'] as List<Object?>)
          .cast<num?>();
      final humidities = (hourly['relative_humidity_2m'] as List<Object?>)
          .cast<num?>();
      final temperatures = (hourly['temperature_2m'] as List<Object?>)
          .cast<num?>();

      final index = _closestIndex(times, instant.toUtc());
      if (index == null || index < 24) return null;

      final pressure = pressures[index];
      final pressure24hAgo = pressures[index - 24];
      if (pressure == null || pressure24hAgo == null) return null;

      return WeatherSnapshot(
        capturedAt: times[index],
        pressureHpa: pressure.toDouble(),
        pressureDelta24hHpa: (pressure - pressure24hAgo).toDouble(),
        humidityPercent: humidities[index]?.toDouble(),
        temperatureCelsius: temperatures[index]?.toDouble(),
      );
    } on Exception {
      return null;
    }
  }

  int? _closestIndex(List<DateTime> times, DateTime target) {
    int? best;
    Duration? bestDistance;
    for (var i = 0; i < times.length; i++) {
      final distance = times[i].difference(target).abs();
      if (bestDistance == null || distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (bestDistance == null || bestDistance > _tolerance) return null;
    return best;
  }
}
