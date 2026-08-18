import 'package:cloud_functions/cloud_functions.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/pressure_forecast.dart';
import '../../domain/entities/weather_report.dart';
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

  /// How far the weather card looks ahead.
  ///
  /// Every day the sheet lists needs hours behind it, because the readings a
  /// picked day shows are averaged from them — `WeatherReport.forecastDayCount`
  /// days at 24, which is 240 and exactly the callable's own ceiling.
  static const int _reportHoursForward = WeatherReport.forecastDayCount * 24;

  Future<Map<Object?, Object?>?> _call({
    required double latitude,
    required double longitude,
    required int hoursBack,
    required int hoursForward,
    bool full = false,
  }) async {
    // Coordinates are rounded before they are logged: the backend already
    // rounds to ~11km before storing anything, and a log is no place to be
    // more precise about where the user is than the server is.
    final Map<String, Object?> request = <String, Object?>{
      'lat': latitude.toStringAsFixed(1),
      'lon': longitude.toStringAsFixed(1),
      'hoursBack': hoursBack,
      'hoursForward': hoursForward,
      'full': full,
    };

    SdLogger.action(LogTagConstant.weather, 'Call getWeather', request);
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable('getWeather')
          .call<dynamic>(<String, dynamic>{
            'lat': latitude,
            'lon': longitude,
            'hoursBack': hoursBack,
            'hoursForward': hoursForward,
            if (full) 'full': true,
          });
      final Map<Object?, Object?>? data = result.data as Map<Object?, Object?>?;

      SdLogger.info(LogTagConstant.weather, 'getWeather ok', <String, Object?>{
        ...request,
        'hours': (data?['hours'] as List<Object?>?)?.length ?? 0,
        'days': (data?['days'] as List<Object?>?)?.length ?? 0,
        'current': data?['current'] != null,
        // Says whether this cost a WeatherKit call or came off the cache.
        'cached': data?['cached'],
      });

      return data;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      // Best-effort by rule, silent by accident: every weather failure —
      // a missing WeatherKit credential, a refused call, being offline —
      // arrives at the UI as "no weather" and nowhere else. `failed-
      // precondition` here is the backend saying its credentials are unset.
      SdLogger.error(
        LogTagConstant.weather,
        'getWeather failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          ...request,
          'code': error.code,
          'message': error.message,
          'details': error.details,
        },
      );

      return null;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.weather,
        'getWeather failed',
        error: error,
        stackTrace: stackTrace,
        data: request,
      );

      return null;
    }
  }

  Future<List<_Hour>?> _hours({
    required double latitude,
    required double longitude,
    required int hoursBack,
    required int hoursForward,
  }) async {
    final Map<Object?, Object?>? data = await _call(
      latitude: latitude,
      longitude: longitude,
      hoursBack: hoursBack,
      hoursForward: hoursForward,
    );
    final List<Object?>? raw = data?['hours'] as List<Object?>?;

    if (raw == null) return null;

    return raw
        .whereType<Map<Object?, Object?>>()
        .map(_Hour.fromMap)
        .whereType<_Hour>()
        .toList();
  }

  /// Conditions now, the hours ahead and the days after — the weather card's
  /// whole payload, from one call.
  Future<WeatherReport?> report({
    required double latitude,
    required double longitude,
  }) async {
    final Map<Object?, Object?>? data = await _call(
      latitude: latitude,
      longitude: longitude,
      hoursBack: 0,
      hoursForward: _reportHoursForward,
      full: true,
    );

    if (data == null) return null;

    final WeatherReport report = WeatherReport(
      current: _conditions(data['current']),
      hours: (data['hours'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(_hourly)
          .whereType<WeatherHourly>()
          .toList(),
      days: (data['days'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(_daily)
          .whereType<WeatherDaily>()
          .toList(),
    );

    // Nothing to draw is the same answer as no answer, so the card has one
    // empty state rather than two that look identical.
    return report.isEmpty ? null : report;
  }

  WeatherConditions? _conditions(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;

    final DateTime? time = DateTime.tryParse('${raw['time']}');

    if (time == null) return null;

    return WeatherConditions(
      time: time.toUtc(),
      pressureHpa: _double(raw['pressureHpa']),
      pressureTrend: PressureTrend.fromCode(raw['pressureTrend'] as String?),
      temperatureCelsius: _double(raw['temperatureCelsius']),
      apparentTemperatureCelsius: _double(raw['apparentTemperatureCelsius']),
      humidityPercent: _double(raw['humidityPercent']),
      uvIndex: _double(raw['uvIndex']),
      condition: WeatherCondition.fromCode(raw['conditionCode'] as String?),
      windSpeedKph: _double(raw['windSpeedKph']),
      cloudCoverPercent: _double(raw['cloudCoverPercent']),
      visibilityKm: _double(raw['visibilityKm']),
      daylight: raw['daylight'] as bool?,
    );
  }

  /// Null for an hour with no time or no pressure, so one unusable entry does
  /// not cost the series around it.
  WeatherHourly? _hourly(Map<Object?, Object?> raw) {
    final DateTime? time = DateTime.tryParse('${raw['time']}');
    final double? pressure = _double(raw['pressureHpa']);

    if (time == null || pressure == null) return null;

    return WeatherHourly(
      time: time.toUtc(),
      pressureHpa: pressure,
      temperatureCelsius: _double(raw['temperatureCelsius']),
      apparentTemperatureCelsius: _double(raw['apparentTemperatureCelsius']),
      humidityPercent: _double(raw['humidityPercent']),
      uvIndex: _double(raw['uvIndex']),
      condition: WeatherCondition.fromCode(raw['conditionCode'] as String?),
      precipitationChancePercent: _double(raw['precipitationChancePercent']),
      precipitationAmountMm: _double(raw['precipitationAmountMm']),
      windSpeedKph: _double(raw['windSpeedKph']),
      cloudCoverPercent: _double(raw['cloudCoverPercent']),
      visibilityKm: _double(raw['visibilityKm']),
    );
  }

  WeatherDaily? _daily(Map<Object?, Object?> raw) {
    final DateTime? date = DateTime.tryParse('${raw['date']}');

    if (date == null) return null;

    return WeatherDaily(
      date: date.toUtc(),
      condition: WeatherCondition.fromCode(raw['conditionCode'] as String?),
      temperatureMaxCelsius: _double(raw['temperatureMaxCelsius']),
      temperatureMinCelsius: _double(raw['temperatureMinCelsius']),
      precipitationChancePercent: _double(raw['precipitationChancePercent']),
      precipitationAmountMm: _double(raw['precipitationAmountMm']),
      uvIndexMax: _double(raw['uvIndexMax']),
      sunrise: DateTime.tryParse('${raw['sunrise']}')?.toUtc(),
      sunset: DateTime.tryParse('${raw['sunset']}')?.toUtc(),
    );
  }

  double? _double(Object? value) => (value as num?)?.toDouble();

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
          (_Hour h) => PressurePoint(time: h.time, pressureHpa: h.pressureHpa),
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
    final _Hour? dayBefore = _at(
      hours,
      hour.time.subtract(const Duration(hours: 24)),
    );

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
