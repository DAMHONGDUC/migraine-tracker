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
import 'domain/entities/migraine_days_summary.dart';
import 'domain/entities/sleep_correlation_result.dart';
import 'domain/entities/step_correlation_result.dart';
import 'domain/enums/health_range.dart';
import 'domain/enums/insights_tab.dart';
import 'domain/services/correlation_engine.dart';
import 'domain/services/exertion_correlation_engine.dart';
import 'domain/services/medication_effectiveness_engine.dart';
import 'domain/services/migraine_days_engine.dart';
import 'domain/services/sleep_correlation_engine.dart';
import 'domain/services/step_correlation_engine.dart';
import 'presentation/controllers/health_range_controller.dart';
import 'presentation/controllers/insights_tab_controller.dart';
import 'presentation/controllers/pressure_alert_highlight_controller.dart';

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

final migraineDaysEngineProvider = Provider<MigraineDaysEngine>(
  (ref) => const MigraineDaysEngine(),
);

/// Migraine days per month over the recent window.
///
/// Synchronous like the medication analysis, and for the same reason: an
/// empty history is already a result here — six months of zero — rather than
/// a loading state.
final migraineDaysProvider = Provider<MigraineDaysSummary>((ref) {
  final MigraineDaysEngine engine = ref.watch(migraineDaysEngineProvider);
  final List<Attack> attacks =
      ref.watch(attacksStreamProvider).value ?? const <Attack>[];

  return engine.analyze(attacks, now: DateTime.now());
});

final medicationEffectivenessEngineProvider =
    Provider<MedicationEffectivenessEngine>(
      (ref) => const MedicationEffectivenessEngine(),
    );

/// Which of the user's medications actually work.
///
/// Synchronous, unlike the correlation providers: the medication screen and
/// the doctor report both want a figure or nothing, and an empty history is
/// already a result here rather than a loading state.
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
///
/// Matched on the name exactly as the attack recorded it — the attack stores
/// the name, not an id, so a renamed medication legitimately starts a fresh
/// row rather than inheriting one it may not have earned.
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
/// Which of Insights' cards is showing. See [InsightsTabController].
final insightsTabProvider =
    NotifierProvider<InsightsTabController, InsightsTab>(
      InsightsTabController.new,
    );

/// Whether the pressure card should scroll to its alert row and light it up.
/// See [PressureAlertHighlightController].
final pressureAlertHighlightProvider =
    NotifierProvider<PressureAlertHighlightController, bool>(
      PressureAlertHighlightController.new,
    );
