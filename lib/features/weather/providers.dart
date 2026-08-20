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

/// The dev-only faked position. [DevLocation.off] everywhere in a prod
/// flavour, whatever is stored.
final devLocationProvider = NotifierProvider<DevLocationController, DevLocation>(
  DevLocationController.new,
);

/// The real device position, unless a dev build has pinned a city.
///
/// **Watched, not read**: picking a city has to rebuild this, and everything
/// downstream of it, or the change would not land until the next launch.
final locationSourceProvider = Provider<LocationSource>((ref) {
  final GeoPoint? faked = ref.watch(devLocationProvider).point;

  return faked == null
      ? const GeolocatorLocationSource()
      : FakeLocationSource(faked);
});

/// Whether the OS will hand over a position, read WITHOUT prompting.
///
/// The weather card watches this to choose between the reading and the ask,
/// so it must never raise the dialog by itself — the same rule
/// [LocationSource] splits its two methods over. The prompt is raised by the
/// button on that card and by onboarding, and nowhere else.
///
/// **A dev-pinned city answers granted**: there is no OS permission behind a
/// faked point, and a Simulator that reports denied would put an ask on a
/// card that is already working.
///
/// Invalidated by the card after it asks, and on resume — a permission
/// granted in the Settings app is answered while the app is not running.
final locationPermissionProvider = FutureProvider<AppPermissionStatus>((
  ref,
) async {
  if (ref.watch(devLocationProvider).point != null) {
    return AppPermissionStatus.granted;
  }

  return ref.watch(appPermissionProvider).status(AppPermissionType.location);
});

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

/// How long a fetched report is kept after nothing is watching it.
///
/// Matches the backend's own cache TTL: past it the callable would answer
/// from a fresh WeatherKit fetch anyway, so holding it longer would serve
/// numbers the server has already replaced.
const Duration weatherReportTtl = Duration(minutes: 60);

/// How long a FAILED read waits before it tries again on its own.
///
/// A miss is usually a moment, not a state: the position has not been fixed
/// yet, the anonymous session is still coming up, the callable is cold. Until
/// this existed the card simply kept the miss — a null is a completed value,
/// so nothing recomputed it while the dashboard stayed on screen, and the
/// user watched "weather unavailable" sit there with no way to ask again.
///
/// Long enough not to hammer a genuinely offline device, short enough that a
/// user still looking at the card sees it heal. It only ticks while something
/// is watching — the provider is `autoDispose` and the timer dies with it, so
/// a backgrounded app retries nothing.
const Duration weatherRetryDelay = Duration(seconds: 30);

/// Everything the weather card draws. Null = offline, no permission, or a
/// backend with no WeatherKit credentials — the card shows one unavailable
/// state for all of them (hard rule 4).
///
/// **Kept alive for [weatherReportTtl] after its last listener goes.** The
/// card is built only on the Insights weather tab, so plain `autoDispose`
/// threw the report away on every tab switch and refetched on the way back —
/// which emptied the card for the length of a round trip each time. Holding
/// it means switching tabs is silent: the same data is still there.
///
/// Still `autoDispose` underneath, so it does eventually go rather than
/// pinning a location-derived payload in memory for the whole session.
///
/// **Only a success is kept.** Keeping the result unconditionally pinned a
/// FAILURE for the same hour: one early miss — location not answered yet, the
/// anonymous session not up — and the card said "unavailable" until the TTL
/// expired, with every return to the tab serving the same cached nothing
/// instead of retrying. A failed read must cost the next visit a retry.
final weatherReportProvider = FutureProvider.autoDispose((ref) async {
  final KeepAliveLink link = ref.keepAlive();
  Timer? expiry;

  // Cancelled on dispose: an uncancelled timer outlives the provider, and a
  // widget test then fails on a pending timer rather than on what it tests.
  ref.onDispose(() => expiry?.cancel());

  try {
    final WeatherReport? report = await ref
        .watch(weatherRepositoryProvider)
        .report();

    // Null is the best-effort failure (hard rule 4), not an empty forecast,
    // so a retry is scheduled and a miss the user is looking at heals itself.
    // The timer dies with the provider: a card nobody watches asks nothing.
    if (report == null) {
      link.close();
      expiry = Timer(weatherRetryDelay, ref.invalidateSelf);

      return null;
    }

    expiry = Timer(weatherReportTtl, link.close);

    return report;
  } catch (_) {
    link.close();
    // Same reason as a null report: a thrown read is a moment, and the card
    // has no other way to ask again.
    expiry = Timer(weatherRetryDelay, ref.invalidateSelf);
    rethrow;
  }
});

/// The name of the place the device is in — the same position the weather is
/// read for, put through the platform's geocoder rather than the backend.
final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => GeocodedPlaceRepository(
    ref.watch(locationSourceProvider),
    const GeocodingPlaceNameSource(),
  ),
);

/// What the weather card writes above the temperature. Null = no position, no
/// permission, or a coordinate the OS has no name for — the card then draws
/// the reading with no place line, never an "unknown" one.
///
/// **Keyed by the app's language**, so switching it refetches the name in the
/// new one rather than leaving a Vietnamese card labelled in English.
///
/// **A success is kept for [weatherReportTtl]**, the same hour the reading it
/// labels is, and for the same reason: the dashboard rebuilds this on every
/// visit, and re-geocoding an unchanged position is a platform round trip the
/// user paid nothing for. A failure is not kept — the next visit retries.
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
