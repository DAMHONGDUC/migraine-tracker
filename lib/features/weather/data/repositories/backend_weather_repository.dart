import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/pressure_forecast.dart';
import '../../domain/entities/weather_report.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/backend_weather_data_source.dart';
import '../datasources/location_source.dart';

/// Weather for the user's current location, read through the backend.
class BackendWeatherRepository implements WeatherRepository {
  const BackendWeatherRepository(this._location, this._dataSource);

  final LocationSource _location;
  final BackendWeatherDataSource _dataSource;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      SdLogger.info(
        LogTagConstant.weather,
        'Weather snapshot skipped: no location/permission',
      );

      return null;
    }

    final WeatherSnapshot? snapshot = await _dataSource.snapshotAt(
      latitude: point.latitude,
      longitude: point.longitude,
      instant: instant,
    );

    SdLogger.debug(
      LogTagConstant.weather,
      'Weather snapshot fetched',
      snapshot?.pressureHpa,
    );

    return snapshot;
  }

  @override
  Future<PressureForecast?> pressureForecast() async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      SdLogger.info(
        LogTagConstant.weather,
        'Pressure forecast skipped: no location/permission',
      );

      return null;
    }

    final DateTime now = DateTime.now().toUtc();
    final List<PressurePoint>? points = await _dataSource.pressureSeries(
      latitude: point.latitude,
      longitude: point.longitude,
      now: now,
    );

    if (points == null) return null;

    return PressureForecast(generatedAt: now, points: points);
  }

  @override
  Future<WeatherReport?> report() async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      SdLogger.info(
        LogTagConstant.weather,
        'Weather report skipped: no location/permission',
      );

      return null;
    }

    final WeatherReport? report = await _dataSource.report(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    // Not `report?.hours.length`: that logs "— null" for a failed fetch, which reads the same as a fetch that returned nothing.
    if (report == null) {
      SdLogger.warning(
        LogTagConstant.weather,
        'Weather report unavailable — see the getWeather line',
      );
    } else {
      SdLogger.info(
        LogTagConstant.weather,
        'Weather report fetched',
        <String, Object?>{
          'hours': report.hours.length,
          'days': report.days.length,
          'current': report.current != null,
        },
      );
    }

    return report;
  }
}
