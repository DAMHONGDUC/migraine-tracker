import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/repositories/drift_attack_repository.dart';
import 'domain/repositories/attack_repository.dart';

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => DriftAttackRepository(ref.watch(databaseProvider)),
);
