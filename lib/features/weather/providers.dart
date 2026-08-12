import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// KeepAliveLink is not in the main barrel.
import 'package:hooks_riverpod/misc.dart' show KeepAliveLink;

import '../../core/constants/firebase_constants.dart';
import '../../core/db/database_provider.dart';
import 'data/datasources/backend_weather_data_source.dart';
import 'data/datasources/location_source.dart';
import 'data/repositories/backend_weather_repository.dart';
import 'data/repositories/drift_daily_pressure_repository.dart';
import 'domain/entities/daily_pressure.dart';
import 'domain/entities/weather_report.dart';
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

/// How long a fetched report is kept after nothing is watching it.
///
/// Matches the backend's own cache TTL: past it the callable would answer
/// from a fresh WeatherKit fetch anyway, so holding it longer would serve
/// numbers the server has already replaced.
const Duration weatherReportTtl = Duration(minutes: 60);

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

    // Null is the best-effort failure (hard rule 4), not an empty forecast —
    // so it is not worth an hour of memory either.
    if (report == null) {
      link.close();

      return null;
    }

    expiry = Timer(weatherReportTtl, link.close);

    return report;
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
