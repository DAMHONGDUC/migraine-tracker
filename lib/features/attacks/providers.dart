import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../weather/providers.dart';
import 'data/repositories/drift_attack_repository.dart';
import 'domain/entities/attack.dart';
import 'domain/repositories/attack_repository.dart';
import 'domain/services/weather_attach_service.dart';

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => DriftAttackRepository(ref.watch(databaseProvider)),
);

final attacksStreamProvider = StreamProvider<List<Attack>>(
  (ref) => ref.watch(attackRepositoryProvider).watchAll(),
);

/// One attack by id; emits null once it's deleted so the detail screen can
/// show its gone-state instead of stale data.
final attackByIdProvider = StreamProvider.autoDispose.family<Attack?, String>(
  (ref, id) => ref.watch(attackRepositoryProvider).watchById(id),
);

final weatherAttachServiceProvider = Provider<WeatherAttachService>(
  (ref) => WeatherAttachService(
    ref.watch(attackRepositoryProvider),
    ref.watch(weatherRepositoryProvider),
  ),
);
