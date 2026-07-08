import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/data/db/app_database.dart';
import 'package:migraine_tracker/data/repositories/medication_repository.dart';
import 'package:migraine_tracker/domain/models/medication.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = MedicationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert inserts then updates by id, sorted by name', () async {
    await repository.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await repository.upsert(const Medication(id: 'm2', name: 'Ibuprofen'));

    expect(await repository.watchAll().first, [
      const Medication(id: 'm2', name: 'Ibuprofen'),
      const Medication(id: 'm1', name: 'Sumatriptan'),
    ]);

    await repository.upsert(const Medication(id: 'm1', name: 'Rizatriptan'));
    final meds = await repository.watchAll().first;
    expect(meds.map((m) => m.name), ['Ibuprofen', 'Rizatriptan']);
  });

  test('deleteById and deleteAll', () async {
    await repository.upsert(const Medication(id: 'm1', name: 'A'));
    await repository.upsert(const Medication(id: 'm2', name: 'B'));

    await repository.deleteById('m1');
    expect((await repository.watchAll().first).map((m) => m.id), ['m2']);

    await repository.deleteAll();
    expect(await repository.watchAll().first, isEmpty);
  });
}
