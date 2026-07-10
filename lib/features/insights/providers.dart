import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/providers.dart';
import 'domain/entities/correlation_result.dart';
import 'domain/services/correlation_engine.dart';

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
