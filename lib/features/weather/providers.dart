import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/db/database_provider.dart';
import 'data/datasources/backend_weather_data_source.dart';
import 'data/datasources/location_source.dart';
import 'data/repositories/backend_weather_repository.dart';
import 'data/repositories/drift_daily_pressure_repository.dart';
import 'domain/entities/daily_pressure.dart';
import 'domain/repositories/daily_pressure_repository.dart';
import 'domain/repositories/weather_repository.dart';
import 'domain/services/daily_pressure_recorder.dart';

final locationSourceProvider = Provider<LocationSource>(
  (ref) => const GeolocatorLocationSource(),
);

/// The app's only weather source, and it is the backend — there is no HTTP
/// client here any more, because the app calls no weather API of its own.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => BackendWeatherRepository(
    ref.watch(locationSourceProvider),
    BackendWeatherDataSource(
      FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion),
    ),
  ),
);

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
