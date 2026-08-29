import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../health/domain/entities/sleep_night.dart';
import '../health/domain/entities/step_day.dart';
import '../health/domain/entities/step_hour.dart';
import '../health/providers.dart';
import '../weather/domain/entities/daily_pressure.dart';
import '../weather/providers.dart';
import 'domain/entities/correlation_result.dart';
import 'domain/entities/exertion_correlation_result.dart';
import 'domain/entities/medication_effectiveness_result.dart';
import 'domain/entities/medication_overuse_result.dart';
import 'domain/entities/migraine_days_summary.dart';
import 'domain/entities/pressure_timeline.dart';
import 'domain/entities/sleep_correlation_result.dart';
import 'domain/entities/step_correlation_result.dart';
import 'domain/entities/trigger_verdict.dart';
import 'domain/enums/health_range.dart';
import 'domain/enums/insights_tab.dart';
import 'domain/services/correlation_engine.dart';
import 'domain/services/exertion_correlation_engine.dart';
import 'domain/services/medication_effectiveness_engine.dart';
import 'domain/services/medication_overuse_engine.dart';
import 'domain/services/migraine_days_engine.dart';
import 'domain/services/pressure_timeline_builder.dart';
import 'domain/services/sleep_correlation_engine.dart';
import 'domain/services/step_correlation_engine.dart';
import 'domain/services/trigger_verdict_engine.dart';
import 'presentation/controllers/health_range_controller.dart';
import 'presentation/controllers/insights_tab_controller.dart';
import 'presentation/controllers/pressure_alert_highlight_controller.dart';

/// Default engine (15-attack minimum, 5 hPa threshold). The threshold becomes user-tunable in the alerts phase.
final correlationEngineProvider = Provider<CorrelationEngine>(
  (ref) => const CorrelationEngine(),
);

final correlationResultProvider = Provider<AsyncValue<CorrelationResult>>((
  ref,
) {
  final attacks = ref.watch(attacksStreamProvider);
  final engine = ref.watch(correlationEngineProvider);
  // Days are best-effort: while they are loading, or if the read failed, the card still shows the share rather than waiting on a baseline it may never get.
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

/// The sleep insight.
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

/// The step insight.
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

final pressureTimelineBuilderProvider = Provider<PressureTimelineBuilder>(
  (ref) => const PressureTimelineBuilder(),
);

/// The month's pressure line with this user's attacks marked on it.
final pressureTimelineProvider = Provider<PressureTimeline>((ref) {
  final PressureTimelineBuilder builder = ref.watch(
    pressureTimelineBuilderProvider,
  );

  return builder.build(
    attacks: ref.watch(attacksStreamProvider).value ?? const <Attack>[],
    readings:
        ref.watch(dailyPressureHistoryProvider).value ??
        const <DailyPressure>[],
    now: DateTime.now(),
  );
});

final triggerVerdictEngineProvider = Provider<TriggerVerdictEngine>(
  (ref) => const TriggerVerdictEngine(),
);

/// Is weather actually this user's trigger, and what is if it is not.
final triggerVerdictProvider = Provider<TriggerVerdict>((ref) {
  final TriggerVerdictEngine engine = ref.watch(triggerVerdictEngineProvider);

  return engine.analyze(
    pressure:
        ref.watch(correlationResultProvider).value ??
        const CorrelationInsufficientData(
          attacksAnalyzed: 0,
          requiredAttacks: CorrelationEngine.defaultMinAttacks,
        ),
    sleep: ref.watch(sleepCorrelationProvider).value ?? const SleepNotConnected(),
    steps: ref.watch(stepCorrelationProvider).value ?? const StepNotConnected(),
  );
});

final migraineDaysEngineProvider = Provider<MigraineDaysEngine>(
  (ref) => const MigraineDaysEngine(),
);

/// Migraine days per month over the recent window.
final migraineDaysProvider = Provider<MigraineDaysSummary>((ref) {
  final MigraineDaysEngine engine = ref.watch(migraineDaysEngineProvider);
  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  return engine.analyze(attacks, now: DateTime.now());
});

final medicationOveruseEngineProvider = Provider<MedicationOveruseEngine>(
  (ref) => const MedicationOveruseEngine(),
);

/// Whether acute medication is being taken often enough to start causing attacks. Free, and never gated: a safety count is not a feature to sell.
final medicationOveruseProvider = Provider<MedicationOveruseResult>((ref) {
  final MedicationOveruseEngine engine = ref.watch(
    medicationOveruseEngineProvider,
  );
  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  return engine.analyze(attacks, now: DateTime.now());
});

final medicationEffectivenessEngineProvider =
    Provider<MedicationEffectivenessEngine>(
      (ref) => const MedicationEffectivenessEngine(),
    );

/// Which of the user's medications actually work.
final medicationEffectivenessProvider = Provider<MedicationEffectivenessResult>(
  (ref) {
    final MedicationEffectivenessEngine engine = ref.watch(
      medicationEffectivenessEngineProvider,
    );
    final List<Attack> attacks =
        ref.watch(attacksStreamProvider).value ?? const <Attack>[];

    return engine.analyze(attacks);
  },
);

/// One medication's row, or null while nothing has been taken for it.
final medicationEffectivenessRowProvider =
    Provider.family<MedicationEffectiveness?, String>((ref, medicationName) {
      final MedicationEffectivenessResult result = ref.watch(
        medicationEffectivenessProvider,
      );

      if (result is! MedicationEffectivenessInsight) {
        return null;
      }

      final String name = medicationName.trim();

      for (final MedicationEffectiveness row in result.medications) {
        if (row.name == name) return row;
      }

      return null;
    });

/// The range each health chart is showing. Two controllers, not one: someone looking at six months of steps has not asked to leave last night's sleep.
final stepRangeProvider = NotifierProvider<StepRangeController, HealthRange>(
  StepRangeController.new,
);

final sleepRangeProvider = NotifierProvider<SleepRangeController, HealthRange>(
  SleepRangeController.new,
);

/// Step days over the selected range. Empty while steps are disconnected — the read stops at the source rather than being discarded afterwards.
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

/// Today's steps by hour — the Day range only, where a single daily total would be one bar.
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
/// Which of Insights' cards is showing. See [InsightsTabController].
final insightsTabProvider =
    NotifierProvider<InsightsTabController, InsightsTab>(
      InsightsTabController.new,
    );

/// Whether the pressure card should scroll to its alert row and light it up. See [PressureAlertHighlightController].
final pressureAlertHighlightProvider =
    NotifierProvider<PressureAlertHighlightController, bool>(
      PressureAlertHighlightController.new,
    );
