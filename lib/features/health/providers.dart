import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/datasources/cycle_sample_source.dart';
import 'data/datasources/sleep_sample_source.dart';
import 'data/datasources/step_sample_source.dart';
import 'data/repositories/health_kit_repository.dart';
import 'domain/entities/cycle_day.dart';
import 'domain/entities/health_connections.dart';
import 'domain/entities/sleep_night.dart';
import 'domain/entities/sleep_summary.dart';
import 'domain/entities/step_day.dart';
import 'domain/entities/step_summary.dart';
import 'domain/repositories/health_repository.dart';
import 'domain/services/cycle_day_aggregator.dart';
import 'domain/services/cycle_window_calculator.dart';
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

final cycleSampleSourceProvider = Provider<CycleSampleSource>(
  (ref) => HealthKitCycleSampleSource(),
);

/// HealthKit, and nothing else.
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthKitRepository(
    ref.watch(sleepSampleSourceProvider),
    const SleepNightAggregator(),
    ref.watch(stepSampleSourceProvider),
    const StepDayAggregator(),
    const StepHourAggregator(),
    ref.watch(cycleSampleSourceProvider),
    const CycleDayAggregator(),
  );
});

/// Whether to offer the feature at all — false off iOS, where the plugin would talk to Google Fit. Every health surface checks this first.
final healthAvailableProvider = Provider<bool>(
  (ref) => ref.watch(healthRepositoryProvider).isAvailable,
);

final healthSummariserProvider = Provider<HealthSummariser>(
  (ref) => const HealthSummariser(),
);

final cycleWindowCalculatorProvider = Provider<CycleWindowCalculator>(
  (ref) => const CycleWindowCalculator(),
);

/// The recent cycle, read on demand and never stored. Empty while the switch is off, so nothing asks HealthKit for reproductive data the user has not offered.
final cycleDaysProvider = FutureProvider.autoDispose<List<CycleDay>>((
  ref,
) async {
  if (!ref.watch(healthControllerProvider).cycle) return const <CycleDay>[];

  final DateTime now = DateTime.now();

  return ref
      .watch(healthRepositoryProvider)
      .cycleDays(
        // Two cycles back: enough to place today in a window, and no more history than that needs.
        from: now.subtract(const Duration(days: 70)),
        to: now,
      );
});

/// Where today sits relative to the nearest period start: -2 through +3, or null when it is outside every window or there is no data.
final todayCycleDayProvider = Provider.autoDispose<int?>((ref) {
  final List<CycleDay> days =
      ref.watch(cycleDaysProvider).value ?? const <CycleDay>[];

  if (days.isEmpty) return null;
  return ref
      .watch(cycleWindowCalculatorProvider)
      .dayInCycle(days, DateTime.now());
});

/// The last week of nights, for the sleep screen's own card — what was measured, before any correlation is drawn from it.
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

/// The last week of step counts, for the activity screen's own card. Same shape and same reason as [sleepSummaryProvider].
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
    NotifierProvider<HealthController, HealthConnections>(HealthController.new);
