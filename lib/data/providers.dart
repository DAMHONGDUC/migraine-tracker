import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'db/app_database.dart';
import 'repositories/attack_repository.dart';
import 'repositories/medication_repository.dart';

/// Single app-wide database instance. Override with an in-memory database
/// in tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => AttackRepository(ref.watch(databaseProvider)),
);

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(ref.watch(databaseProvider)),
);
