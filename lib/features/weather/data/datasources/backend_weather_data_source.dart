import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/pressure_forecast.dart';
import '../../domain/entities/weather_snapshot.dart';

/// Reads weather through the `getWeather` callable.
///
/// **The app has no weather API of its own, and must not gain one.**
/// WeatherKit's ES256 signing key cannot ship in a binary, so the app asks the
/// backend and the backend asks Apple (CLAUDE.md's tech-stack rule). Nothing
/// here knows a provider name — swapping Apple for something else is a change
/// on the server alone.
///
/// Every method returns null on any failure. Hard rule 4: logging an attack
/// works fully offline, so a weather read is best-effort and never an error.
class BackendWeatherDataSource {
  const BackendWeatherDataSource(this._functions);

  final FirebaseFunctions _functions;

  /// Nearest hourly sample to the target instant must be within this.
  static const Duration _tolerance = Duration(minutes: 90);

  /// How far back the snapshot window reaches, so an attack logged offline is
  /// backfilled with the weather at *its* start time rather than today's.
  static const int _backfillDays = 7;

  Future<List<_Hour>?> _hours({
    required double latitude,
    required double longitude,
    required int hoursBack,
    required int hoursForward,
  }) async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable('getWeather')
          .call<dynamic>(<String, dynamic>{
            'lat': latitude,
            'lon': longitude,
            'hoursBack': hoursBack,
            'hoursForward': hoursForward,
          });
      final List<Object?>? raw =
          (result.data as Map<Object?, Object?>?)?['hours'] as List<Object?>?;

      if (raw == null) return null;

      return raw
          .whereType<Map<Object?, Object?>>()
          .map(_Hour.fromMap)
          .whereType<_Hour>()
          .toList();
    } on Exception {
      return null;
    }
  }

  /// Hourly pressure for the forecast chart: 12h behind, 48h ahead.
  Future<List<PressurePoint>?> pressureSeries({
    required double latitude,
    required double longitude,
    required DateTime now,
  }) async {
    final List<_Hour>? hours = await _hours(
      latitude: latitude,
      longitude: longitude,
      hoursBack: 12,
      hoursForward: 48,
    );

    if (hours == null) return null;

    final List<PressurePoint> points = hours
        .map(
          (_Hour h) =>
              PressurePoint(time: h.time, pressureHpa: h.pressureHpa),
        )
        .toList();

    return points.isEmpty ? null : points;
  }

  /// The weather at [instant], with the 24h delta the insight cards read.
  ///
  /// The window reaches a day further back than [instant] on purpose — the
  /// delta needs the reading 24h before it, so a window that merely contains
  /// the instant would return a snapshot with nothing to compare against.
  Future<WeatherSnapshot?> snapshotAt({
    required double latitude,
    required double longitude,
    required DateTime instant,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final int hoursSince = now.difference(instant.toUtc()).inHours;
    final List<_Hour>? hours = await _hours(
      latitude: latitude,
      longitude: longitude,
      // A day beyond the instant, and never less than the backfill window.
      hoursBack: hoursSince + 24 > _backfillDays * 24
          ? _backfillDays * 24
          : hoursSince + 24,
      hoursForward: hoursSince <= 0 ? 1 : 0,
    );

    if (hours == null || hours.isEmpty) return null;

    final int? index = _closestIndex(hours, instant.toUtc());

    if (index == null) return null;

    final _Hour hour = hours[index];
    final _Hour? dayBefore = _at(hours, hour.time.subtract(const Duration(hours: 24)));

    if (dayBefore == null) return null;

    return WeatherSnapshot(
      capturedAt: hour.time,
      pressureHpa: hour.pressureHpa,
      pressureDelta24hHpa: hour.pressureHpa - dayBefore.pressureHpa,
      humidityPercent: hour.humidityPercent,
      temperatureCelsius: hour.temperatureCelsius,
    );
  }

  /// The sample nearest [target], or null when the series does not reach it.
  int? _closestIndex(List<_Hour> hours, DateTime target) {
    int? best;
    Duration? bestDistance;

    for (int i = 0; i < hours.length; i++) {
      final Duration distance = hours[i].time.difference(target).abs();

      if (bestDistance == null || distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }

    if (bestDistance == null || bestDistance > _tolerance) return null;

    return best;
  }

  _Hour? _at(List<_Hour> hours, DateTime target) {
    final int? index = _closestIndex(hours, target);

    return index == null ? null : hours[index];
  }
}

/// One hour as the callable sends it.
class _Hour {
  const _Hour({
    required this.time,
    required this.pressureHpa,
    this.humidityPercent,
    this.temperatureCelsius,
  });

  final DateTime time;
  final double pressureHpa;
  final double? humidityPercent;
  final double? temperatureCelsius;

  /// Null for a row that cannot be read, so one bad entry does not lose the
  /// series around it.
  static _Hour? fromMap(Map<Object?, Object?> map) {
    final DateTime? time = DateTime.tryParse('${map['time']}');
    final num? pressure = map['pressureHpa'] as num?;

    if (time == null || pressure == null) return null;

    return _Hour(
      time: time.toUtc(),
      pressureHpa: pressure.toDouble(),
      humidityPercent: (map['humidityPercent'] as num?)?.toDouble(),
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble(),
    );
  }
}
