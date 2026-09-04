import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/services/default_medication_seeder.dart';

void main() {
  late AppDatabase db;
  late DefaultMedicationSeeder seeder;
  late DriftMedicationRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftMedicationRepository(db);
    seeder = DefaultMedicationSeeder(repository);
  });

  tearDown(() async {
    await db.close();
  });

  test('a brand-new account starts with one medication', () async {
    await seeder.seedIfEmpty();

    final List<Medication> medications = await repository.getAll();

    expect(medications.map((Medication m) => m.name), <String>[
      DefaultMedicationSeeder.defaultName,
    ]);
    expect(medications.single.createdAt, isNotNull);
  });

  // The case that makes this safe on every sign-in: an anonymous session that
  // already had medications, or a sync pull that landed first.
  test('a list that already holds something is left alone', () async {
    await repository.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));

    await seeder.seedIfEmpty();

    expect(await repository.getAll(), <Medication>[
      const Medication(id: 'm1', name: 'Sumatriptan'),
    ]);
  });

  test('seeding twice does not produce a second row', () async {
    await seeder.seedIfEmpty();
    await seeder.seedIfEmpty();

    expect(await repository.getAll(), hasLength(1));
  });
}
