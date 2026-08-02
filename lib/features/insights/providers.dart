import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/domain/entities/attack.dart';
import '../attacks/providers.dart';
import '../health/domain/entities/sleep_night.dart';
import '../health/providers.dart';
import 'domain/entities/correlation_result.dart';
import 'domain/entities/sleep_correlation_result.dart';
import 'domain/services/correlation_engine.dart';
import 'domain/services/sleep_correlation_engine.dart';

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

final sleepCorrelationEngineProvider = Provider<SleepCorrelationEngine>(
  (ref) => const SleepCorrelationEngine(),
);

/// The sleep insight. Reads HealthKit only while the user has Apple Health
/// connected — disconnecting stops the read at the source rather than
/// throwing the result away afterwards.
final sleepCorrelationProvider = FutureProvider<SleepCorrelationResult>((
  ref,
) async {
  if (!ref.watch(healthControllerProvider)) return const SleepNotConnected();

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
