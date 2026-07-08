import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/drift_medication_repository.dart';
import 'domain/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => DriftMedicationRepository(ref.watch(databaseProvider)),
);
