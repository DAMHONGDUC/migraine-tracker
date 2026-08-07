import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../health/domain/entities/sleep_night.dart';
import '../health/domain/entities/step_day.dart';
import '../health/providers.dart';
import 'domain/entities/correlation_result.dart';
import 'domain/entities/exertion_correlation_result.dart';
import 'domain/entities/sleep_correlation_result.dart';
import 'domain/entities/step_correlation_result.dart';
import 'domain/services/correlation_engine.dart';
import 'domain/services/exertion_correlation_engine.dart';
import 'domain/services/sleep_correlation_engine.dart';
import 'domain/services/step_correlation_engine.dart';

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
  return attacks.whenData(engine.analyze);
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
