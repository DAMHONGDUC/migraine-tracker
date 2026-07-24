import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/pressure_forecast.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/location_source.dart';
import '../datasources/open_meteo_data_source.dart';

class OpenMeteoWeatherRepository implements WeatherRepository {
  const OpenMeteoWeatherRepository(this._location, this._dataSource);

  final LocationSource _location;
  final OpenMeteoDataSource _dataSource;

  @override
  Future<WeatherSnapshot?> snapshotAt(DateTime instant) async {
    final point = await _location.currentPosition();
    if (point == null) {
      AppLogger.info('Weather snapshot skipped: no location/permission');
      return null;
    }
    final snapshot = await _dataSource.snapshotAt(
      latitude: point.latitude,
      longitude: point.longitude,
      instant: instant,
    );
    AppLogger.debug('Weather snapshot fetched', snapshot?.pressureHpa);
    return snapshot;
  }

  @override
  Future<PressureForecast?> pressureForecast() async {
    final point = await _location.currentPosition();
    if (point == null) {
      AppLogger.info('Pressure forecast skipped: no location/permission');
      return null;
    }
    final now = DateTime.now().toUtc();
    final points = await _dataSource.pressureSeries(
      latitude: point.latitude,
      longitude: point.longitude,
      now: now,
    );
    if (points == null) return null;
    return PressureForecast(generatedAt: now, points: points);
  }
}
