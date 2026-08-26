import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';

void main() {
  int nextId = 0;

  Attack attack({String? medication, MedicationEffect? effect}) => Attack(
    id: 'a${nextId++}',
    startedAt: DateTime.utc(2026, 7, 1, 8),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
    medicationName: medication,
    medicationEffect: effect,
  );

  setUp(() => nextId = 0);

  group('the repository', () {
    late AppDatabase db;
    late DriftAttackRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftAttackRepository(db);
    });

    tearDown(() => db.close());

    test('records the outcome and reads it back', () async {
      await repository.insert(attack(medication: 'Sumatriptan'));

      await repository.updateMedicationEffect('a0', MedicationEffect.partly);

      expect(
        (await repository.getAll()).single.medicationEffect,
        MedicationEffect.partly,
      );
    });

    test('takes the answer back on null', () async {
      await repository.insert(
        attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
      );

      await repository.updateMedicationEffect('a0', null);

      expect((await repository.getAll()).single.medicationEffect, isNull);
    });

    // Its own method for the same reason updateExertion is: the details
    // sheet never shows it, so a save from there must not blank it.
    test('editing details leaves the outcome alone', () async {
      await repository.insert(
        attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
      );

      await repository.updateDetails(
        'a0',
        symptoms: const <String>['aura'],
        triggers: const <String>[],
      );

      expect(
        (await repository.getAll()).single.medicationEffect,
        MedicationEffect.helped,
      );
    });

    test('recording the outcome marks the row for sync', () async {
      await repository.insert(attack(medication: 'Sumatriptan'));
      final AttackRow before = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a0'))).getSingle();

      await repository.updateMedicationEffect('a0', MedicationEffect.helped);

      final AttackRow after = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a0'))).getSingle();

      expect(after.revision, greaterThan(before.revision));
    });
  });
}
