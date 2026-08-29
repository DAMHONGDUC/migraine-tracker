import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// KeepAliveLink is not in the main barrel.
import 'package:hooks_riverpod/misc.dart' show KeepAliveLink;

import '../../core/constants/firebase_constants.dart';
import '../../core/db/database_provider.dart';
import '../../core/permissions/app_permission.dart';
import 'data/datasources/backend_weather_data_source.dart';
import 'data/datasources/location_source.dart';
import 'data/datasources/place_name_source.dart';
import 'data/repositories/backend_weather_repository.dart';
import 'data/repositories/drift_daily_pressure_repository.dart';
import 'data/repositories/geocoded_place_repository.dart';
import 'domain/entities/daily_pressure.dart';
import 'domain/entities/geo_point.dart';
import 'domain/entities/weather_report.dart';
import 'domain/enums/dev_location.dart';
import 'domain/repositories/daily_pressure_repository.dart';
import 'domain/repositories/place_repository.dart';
import 'domain/repositories/weather_repository.dart';
import 'domain/services/daily_pressure_recorder.dart';
import 'presentation/controllers/dev_location_controller.dart';

/// The dev-only faked position. [DevLocation.off] everywhere in a prod flavour, whatever is stored.
final devLocationProvider = NotifierProvider<DevLocationController, DevLocation>(
  DevLocationController.new,
);

/// The real device position, unless a dev build has pinned a city.
final locationSourceProvider = Provider<LocationSource>((ref) {
  final GeoPoint? faked = ref.watch(devLocationProvider).point;

  return faked == null
      ? const GeolocatorLocationSource()
      : FakeLocationSource(faked);
});

/// Whether the OS will hand over a position, read WITHOUT prompting.
final locationPermissionProvider = FutureProvider<AppPermissionStatus>((
  ref,
) async {
  if (ref.watch(devLocationProvider).point != null) {
    return AppPermissionStatus.granted;
  }

  return ref.watch(appPermissionProvider).status(AppPermissionType.location);
});

/// The app's only weather source, and it is the backend — there is no HTTP client here any more, because the app calls no weather API of its own.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => BackendWeatherRepository(
    ref.watch(locationSourceProvider),
    BackendWeatherDataSource(
      FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion),
    ),
  ),
);

/// One fetch per screen visit; null = offline / no permission (the card shows its unavailable state).
final pressureForecastProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(weatherRepositoryProvider).pressureForecast(),
);

/// How long a fetched report is kept after nothing is watching it.
const Duration weatherReportTtl = Duration(minutes: 60);

/// How long a FAILED read waits before it tries again on its own.
const Duration weatherRetryDelay = Duration(seconds: 30);

/// Everything the weather card draws.
final weatherReportProvider = FutureProvider.autoDispose((ref) async {
  final KeepAliveLink link = ref.keepAlive();
  Timer? expiry;

  // Cancelled on dispose: an uncancelled timer outlives the provider, and a widget test then fails on a pending timer rather than on what it tests.
  ref.onDispose(() => expiry?.cancel());

  try {
    final WeatherReport? report = await ref
        .watch(weatherRepositoryProvider)
        .report();

    // Null is the best-effort failure (hard rule 4), not an empty forecast, so a retry is scheduled and a miss the user is looking at heals itself.
    if (report == null) {
      link.close();
      expiry = Timer(weatherRetryDelay, ref.invalidateSelf);

      return null;
    }

    expiry = Timer(weatherReportTtl, link.close);

    return report;
  } catch (_) {
    link.close();
    // Same reason as a null report: a thrown read is a moment, and the card has no other way to ask again.
    expiry = Timer(weatherRetryDelay, ref.invalidateSelf);
    rethrow;
  }
});

/// The name of the place the device is in — the same position the weather is read for, put through the platform's geocoder rather than the backend.
final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => GeocodedPlaceRepository(
    ref.watch(locationSourceProvider),
    const GeocodingPlaceNameSource(),
  ),
);

/// What the weather card writes above the temperature.
final placeNameProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  String localeIdentifier,
) async {
  final KeepAliveLink link = ref.keepAlive();
  Timer? expiry;

  ref.onDispose(() => expiry?.cancel());

  try {
    final String? name = await ref
        .watch(placeRepositoryProvider)
        .currentPlaceName(localeIdentifier: localeIdentifier);

    if (name == null) {
      link.close();

      return null;
    }

    expiry = Timer(weatherReportTtl, link.close);

    return name;
  } catch (_) {
    link.close();
    rethrow;
  }
});

final dailyPressureRepositoryProvider = Provider<DailyPressureRepository>(
  (ref) => DriftDailyPressureRepository(ref.watch(databaseProvider)),
);

/// Records one reading per day, so the correlation has days without an attack to compare against. Fired unawaited on launch and resume.
final dailyPressureRecorderProvider = Provider<DailyPressureRecorder>(
  (ref) => DailyPressureRecorder(
    ref.watch(dailyPressureRepositoryProvider),
    ref.watch(weatherRepositoryProvider),
  ),
);

/// The denominator the correlation reads, over the analysis window.
final dailyPressureHistoryProvider = FutureProvider<List<DailyPressure>>(
  (ref) => ref
      .watch(dailyPressureRepositoryProvider)
      .since(DateTime.now().subtract(const Duration(days: 365))),
);
