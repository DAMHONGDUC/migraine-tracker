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
    if (point == null) return null;
    return _dataSource.snapshotAt(
      latitude: point.latitude,
      longitude: point.longitude,
      instant: instant,
    );
  }
}
