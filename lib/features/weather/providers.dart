import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/db/database_provider.dart';
import 'data/datasources/location_source.dart';
import 'data/datasources/open_meteo_data_source.dart';
import 'data/repositories/drift_daily_pressure_repository.dart';
import 'data/repositories/open_meteo_weather_repository.dart';
import 'domain/entities/daily_pressure.dart';
import 'domain/repositories/daily_pressure_repository.dart';
import 'domain/repositories/weather_repository.dart';
import 'domain/services/daily_pressure_recorder.dart';

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

/// One fetch per screen visit; null = offline / no permission (the card
/// shows its unavailable state).
final pressureForecastProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(weatherRepositoryProvider).pressureForecast(),
);

final dailyPressureRepositoryProvider = Provider<DailyPressureRepository>(
  (ref) => DriftDailyPressureRepository(ref.watch(databaseProvider)),
);

/// Records one reading per day, so the correlation has days without an
/// attack to compare against. Fired unawaited on launch and resume.
final dailyPressureRecorderProvider = Provider<DailyPressureRecorder>(
  (ref) => DailyPressureRecorder(
    ref.watch(dailyPressureRepositoryProvider),
    ref.watch(weatherRepositoryProvider),
  ),
);

/// The denominator the correlation reads, over the analysis window.
///
/// A year: long enough for both sides to fill out, short enough that a
/// climate the user has since moved away from stops counting.
final dailyPressureHistoryProvider = FutureProvider<List<DailyPressure>>(
  (ref) => ref
      .watch(dailyPressureRepositoryProvider)
      .since(DateTime.now().subtract(const Duration(days: 365))),
);
