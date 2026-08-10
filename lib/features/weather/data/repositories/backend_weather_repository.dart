import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/pressure_forecast.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/backend_weather_data_source.dart';
import '../datasources/location_source.dart';

/// Weather for the user's current location, read through the backend.
///
/// The location still comes from the device — the backend is asked about a
/// place, it is never told where the user is by any other route, and it
/// rounds what it receives to ~11km before storing anything.
class BackendWeatherRepository implements WeatherRepository {
  const BackendWeatherRepository(this._location, this._dataSource);

  final LocationSource _location;
  final BackendWeatherDataSource _dataSource;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      AppLogger.info('Weather snapshot skipped: no location/permission');

      return null;
    }

    final WeatherSnapshot? snapshot = await _dataSource.snapshotAt(
      latitude: point.latitude,
      longitude: point.longitude,
      instant: instant,
    );

    AppLogger.debug('Weather snapshot fetched', snapshot?.pressureHpa);

    return snapshot;
  }

  @override
  Future<PressureForecast?> pressureForecast() async {
    final GeoPoint? point = await _location.currentPosition();

    if (point == null) {
      AppLogger.info('Pressure forecast skipped: no location/permission');

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
}
