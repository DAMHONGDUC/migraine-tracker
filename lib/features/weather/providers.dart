import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'data/datasources/location_source.dart';
import 'data/datasources/open_meteo_data_source.dart';
import 'data/repositories/open_meteo_weather_repository.dart';
import 'domain/repositories/weather_repository.dart';

final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenMeteoWeatherRepository(
    ref.watch(locationSourceProvider),
    OpenMeteoDataSource(client),
  );
});
