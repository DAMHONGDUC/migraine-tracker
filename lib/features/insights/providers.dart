import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../health/domain/entities/sleep_night.dart';
import '../health/domain/entities/step_day.dart';
import '../health/domain/entities/step_hour.dart';
import '../health/providers.dart';
import '../history/domain/services/sample_chart_data.dart';
import '../weather/domain/entities/daily_pressure.dart';
import '../weather/providers.dart';
import 'domain/entities/correlation_result.dart';
import 'domain/entities/exertion_correlation_result.dart';
import 'domain/entities/sleep_correlation_result.dart';
import 'domain/entities/step_correlation_result.dart';
import 'domain/enums/health_range.dart';
import 'domain/enums/weather_metric.dart';
import 'domain/services/correlation_engine.dart';
import 'domain/services/exertion_correlation_engine.dart';
import 'domain/services/sleep_correlation_engine.dart';
import 'domain/services/step_correlation_engine.dart';
import 'presentation/controllers/health_range_controller.dart';
import 'presentation/controllers/weather_card_controllers.dart';

/// Default engine (15-attack minimum, 5 hPa threshold). The threshold
/// becomes user-tunable in the alerts phase.
final correlationEngineProvider = Provider<CorrelationEngine>(
  (ref) => const CorrelationEngine(),
);

final correlationResultProvider = Provider<AsyncValue<CorrelationResult>>((
  ref,
) {
  final attacks = ref.watch(attacksStreamProvider);
  final engine = ref.watch(correlationEngineProvider);
  // Days are best-effort: while they are loading, or if the read failed, the
  // card still shows the share rather than waiting on a baseline it may
  // never get.
  final List<DailyPressure> days =
      ref.watch(dailyPressureHistoryProvider).value ?? const <DailyPressure>[];

  return attacks.whenData(
    (List<Attack> list) => engine.analyze(list, days: days),
  );
});

final exertionCorrelationEngineProvider = Provider<ExertionCorrelationEngine>(
  (ref) => const ExertionCorrelationEngine(),
);

final exertionCorrelationResultProvider =
    Provider<AsyncValue<ExertionCorrelationResult>>((ref) {
      final attacks = ref.watch(attacksStreamProvider);
      final engine = ref.watch(exertionCorrelationEngineProvider);
      return attacks.whenData(engine.analyze);
    });

final sleepCorrelationEngineProvider = Provider<SleepCorrelationEngine>(
  (ref) => const SleepCorrelationEngine(),
);

/// The sleep insight. Reads HealthKit only while the user has Apple Health
/// connected — disconnecting stops the read at the source rather than
/// throwing the result away afterwards.
final sleepCorrelationProvider = FutureProvider<SleepCorrelationResult>((
  ref,
) async {
  if (!ref.watch(healthControllerProvider).sleep) {
    return const SleepNotConnected();
  }

  final SleepCorrelationEngine engine = ref.watch(sleepCorrelationEngineProvider);
  final List<Attack> attacks = await ref.watch(attacksStreamProvider.future);
  final DateTime now = DateTime.now();
  final DateTime from = DateTime(
    now.year,
    now.month,
    now.day - SleepCorrelationEngine.defaultLookbackDays,
  );

  final List<SleepNight> nights = await ref
      .watch(healthRepositoryProvider)
      .sleepNights(from: from, to: now);

  return engine.analyze(attacks: attacks, nights: nights);
});

final stepCorrelationEngineProvider = Provider<StepCorrelationEngine>(
  (ref) => const StepCorrelationEngine(),
);

/// The step insight. Reads HealthKit only while the user has Apple Health
/// connected — disconnecting stops the read at the source rather than
/// throwing the result away afterwards.
final stepCorrelationProvider = FutureProvider<StepCorrelationResult>((
  ref,
) async {
  if (!ref.watch(healthControllerProvider).steps) {
    return const StepNotConnected();
  }

  final StepCorrelationEngine engine = ref.watch(stepCorrelationEngineProvider);
  final List<Attack> attacks = await ref.watch(attacksStreamProvider.future);
  final DateTime now = DateTime.now();
  final DateTime from = DateTime(
    now.year,
    now.month,
    now.day - StepCorrelationEngine.defaultLookbackDays,
  );

  final List<StepDay> days = await ref
      .watch(healthRepositoryProvider)
      .stepDays(from: from, to: now);

  return engine.analyze(attacks: attacks, days: days);
});

/// Which reading the weather card's hourly row shows, and which day of its
/// week is selected. See [WeatherMetricController] / [WeatherDayController].
final weatherMetricProvider =
    NotifierProvider<WeatherMetricController, WeatherMetric>(
      WeatherMetricController.new,
    );

final weatherDayProvider = NotifierProvider<WeatherDayController, int>(
  WeatherDayController.new,
);

/// The range each health chart is showing. Two controllers, not one: someone
/// looking at six months of steps has not asked to leave last night's sleep.
final stepRangeProvider = NotifierProvider<StepRangeController, HealthRange>(
  StepRangeController.new,
);

final sleepRangeProvider = NotifierProvider<SleepRangeController, HealthRange>(
  SleepRangeController.new,
);

/// Step days over the selected range. Empty while steps are disconnected —
/// the read stops at the source rather than being discarded afterwards.
final rangedStepDaysProvider = FutureProvider<List<StepDay>>((ref) async {
  if (!ref.watch(healthControllerProvider).steps) return const <StepDay>[];

  final HealthRange range = ref.watch(stepRangeProvider);
  final DateTime now = DateTime.now();

  return ref
      .watch(healthRepositoryProvider)
      .stepDays(
        from: DateTime(now.year, now.month, now.day - (range.days - 1)),
        to: now,
      );
});

/// Today's steps by hour — the Day range only, where a single daily total
/// would be one bar.
final stepHoursProvider = FutureProvider<List<StepHour>>((ref) async {
  if (!ref.watch(healthControllerProvider).steps) return const <StepHour>[];

  final DateTime now = DateTime.now();

  return ref
      .watch(healthRepositoryProvider)
      .stepHours(from: DateTime(now.year, now.month, now.day), to: now);
});

/// Sleep nights over the selected range. Same shape as the step one.
final rangedSleepNightsProvider = FutureProvider<List<SleepNight>>((ref) async {
  if (!ref.watch(healthControllerProvider).sleep) return const <SleepNight>[];

  final HealthRange range = ref.watch(sleepRangeProvider);
  final DateTime now = DateTime.now();

  return ref
      .watch(healthRepositoryProvider)
      .sleepNights(
        from: DateTime(now.year, now.month, now.day - (range.days - 1)),
        to: now,
      );
});

/// The fabricated results behind a locked analysis card.
///
/// Run through the SAME engines as the real ones, so a blurred preview cannot
/// drift from what premium actually unlocks — and built from
/// [SampleChartData], never the user's own attacks: a cover over real numbers
/// still leaves them in the tree, one screenshot away.
final sampleExertionCorrelationProvider = Provider<ExertionCorrelationResult>((
  ref,
) {
  return ref
      .watch(exertionCorrelationEngineProvider)
      .analyze(SampleChartData.attacks(now: DateTime.now()));
});

final sampleSleepCorrelationProvider = Provider<SleepCorrelationResult>((ref) {
  final DateTime now = DateTime.now();

  return ref
      .watch(sleepCorrelationEngineProvider)
      .analyze(
        attacks: SampleChartData.attacks(now: now),
        nights: SampleChartData.sleepNights(now: now),
      );
});
