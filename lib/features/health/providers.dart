import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/datasources/sleep_sample_source.dart';
import 'data/datasources/step_sample_source.dart';
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
import 'presentation/controllers/health_controller.dart';

final sleepSampleSourceProvider = Provider<SleepSampleSource>(
  (ref) => HealthKitSleepSampleSource(),
);

final stepSampleSourceProvider = Provider<StepSampleSource>(
  (ref) => HealthKitStepSampleSource(),
);

/// HealthKit, and nothing else.
///
/// **There is no dev fake behind this any more** (owner's call). A
/// `DevSeededHealthRepository` used to stand in on the Simulator, where real
/// reads come back empty — but it meant the sleep and activity cards could be
/// showing invented nights on a dev build, which is a worse thing to read
/// than an honest empty card. Health is the one source the app does not own,
/// so it is the one the seed does not invent: check it on a device.
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
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
