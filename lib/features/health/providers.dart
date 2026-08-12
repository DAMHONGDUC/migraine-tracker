import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import 'data/datasources/sleep_sample_source.dart';
import 'data/datasources/step_sample_source.dart';
import 'data/repositories/dev_seeded_health_repository.dart';
import 'data/repositories/health_kit_repository.dart';
import 'domain/entities/health_connections.dart';
import 'domain/entities/sleep_night.dart';
import 'domain/entities/sleep_summary.dart';
import 'domain/entities/step_day.dart';
import 'domain/entities/step_summary.dart';
import 'domain/repositories/health_repository.dart';
import 'domain/services/health_summariser.dart';
import 'domain/services/sleep_night_aggregator.dart';
import 'domain/services/step_day_aggregator.dart';
import 'domain/services/step_hour_aggregator.dart';
import 'presentation/controllers/dev_health_seed_controller.dart';
import 'presentation/controllers/health_controller.dart';

final sleepSampleSourceProvider = Provider<SleepSampleSource>(
  (ref) => HealthKitSleepSampleSource(),
);

final stepSampleSourceProvider = Provider<StepSampleSource>(
  (ref) => HealthKitStepSampleSource(),
);

/// The seed behind the dev-only fake HealthKit (see [DevHealthSeedController]).
final devHealthSeedProvider = NotifierProvider<DevHealthSeedController, int?>(
  DevHealthSeedController.new,
);

/// HealthKit, or the dev fake when the dev seed has run.
///
/// The fake is gated on `!AppEnv.isProd` as well as the seed, so a stray
/// preference could never put invented health data in front of a real user.
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final int? devSeed = ref.watch(devHealthSeedProvider);

  if (!AppEnv.isProd && devSeed != null) {
    return DevSeededHealthRepository(devSeed);
  }

  return HealthKitRepository(
    ref.watch(sleepSampleSourceProvider),
    const SleepNightAggregator(),
    ref.watch(stepSampleSourceProvider),
    const StepDayAggregator(),
    const StepHourAggregator(),
  );
});

/// Whether to offer the feature at all — false off iOS, where the plugin
/// would talk to Google Fit. Every health surface checks this first.
final healthAvailableProvider = Provider<bool>(
  (ref) => ref.watch(healthRepositoryProvider).isAvailable,
);

final healthSummariserProvider = Provider<HealthSummariser>(
  (ref) => const HealthSummariser(),
);

/// The last week of nights, for the sleep screen's own card — what was
/// measured, before any correlation is drawn from it.
///
/// Empty while sleep is disconnected: the read stops at the source rather
/// than the result being thrown away afterwards, the same way the
/// correlation does it.
final sleepSummaryProvider = FutureProvider<SleepSummary>((ref) async {
  if (!ref.watch(healthControllerProvider).sleep) return SleepSummary.empty;

  final DateTime now = DateTime.now();
  final DateTime from = DateTime(
    now.year,
    now.month,
    now.day - (HealthSummariser.windowDays - 1),
  );
  final List<SleepNight> nights = await ref
      .watch(healthRepositoryProvider)
      .sleepNights(from: from, to: now);

  return ref.watch(healthSummariserProvider).sleep(nights);
});

/// The last week of step counts, for the activity screen's own card. Same
/// shape and same reason as [sleepSummaryProvider].
final stepSummaryProvider = FutureProvider<StepSummary>((ref) async {
  if (!ref.watch(healthControllerProvider).steps) return StepSummary.empty;

  final DateTime now = DateTime.now();
  final DateTime from = DateTime(
    now.year,
    now.month,
    now.day - (HealthSummariser.windowDays - 1),
  );
  final List<StepDay> days = await ref
      .watch(healthRepositoryProvider)
      .stepDays(from: from, to: now);

  return ref.watch(healthSummariserProvider).steps(days);
});

/// Which Apple Health sources the user connected (see [HealthController]).
final healthControllerProvider =
    NotifierProvider<HealthController, HealthConnections>(
      HealthController.new,
    );
