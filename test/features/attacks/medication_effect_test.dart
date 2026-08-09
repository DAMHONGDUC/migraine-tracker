import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';
import 'package:migraine_tracker/features/attacks/domain/services/medication_effect_tally.dart';

void main() {
  const MedicationEffectTally tally = MedicationEffectTally();
  int nextId = 0;

  Attack attack({String? medication, MedicationEffect? effect}) => Attack(
    id: 'a${nextId++}',
    startedAt: DateTime.utc(2026, 7, 1, 8),
    intensity: 6,
    location: HeadLocation.right,
    medicationName: medication,
    medicationEffect: effect,
  );

  setUp(() => nextId = 0);

  group('the tally', () {
    test('counts each outcome for the named medication', () {
      final List<Attack> attacks = <Attack>[
        attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
        attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
        attack(medication: 'Sumatriptan', effect: MedicationEffect.partly),
        attack(medication: 'Sumatriptan', effect: MedicationEffect.didNotHelp),
      ];

      final MedicationEffectCount count = tally.forMedication(
        attacks,
        'Sumatriptan',
      );

      expect(count.helped, 2);
      expect(count.partly, 1);
      expect(count.didNotHelp, 1);
      expect(count.answered, 4);
    });

    // The whole point of the denominator: an attack nobody answered is not a
    // failure, and counting it as one makes every drug look worse the less
    // diligent the user is.
    test('an unanswered attack is not counted as a failure', () {
      final List<Attack> attacks = <Attack>[
        attack(medication: 'Ibuprofen', effect: MedicationEffect.helped),
        attack(medication: 'Ibuprofen'),
        attack(medication: 'Ibuprofen'),
      ];

      final MedicationEffectCount count = tally.forMedication(
        attacks,
        'Ibuprofen',
      );

      expect(count.answered, 1);
      expect(count.helped, 1);
      expect(count.didNotHelp, 0);
    });

    test('another medication\'s outcomes never leak in', () {
      final List<Attack> attacks = <Attack>[
        attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
        attack(medication: 'Ibuprofen', effect: MedicationEffect.didNotHelp),
      ];

      expect(tally.forMedication(attacks, 'Sumatriptan').didNotHelp, 0);
      expect(tally.forMedication(attacks, 'Ibuprofen').helped, 0);
    });

    test('attacks with no medication are ignored entirely', () {
      expect(
        tally.forMedication(<Attack>[attack()], 'Sumatriptan').isEmpty,
        isTrue,
      );
    });

    test('a medication nobody has answered for is empty, not zero-helped', () {
      final MedicationEffectCount count = tally.forMedication(
        <Attack>[attack(medication: 'Naproxen')],
        'Naproxen',
      );

      expect(count.isEmpty, isTrue);
      expect(count.answered, 0);
    });

    group('byMedication', () {
      test('lists only the medications with at least one answer', () {
        final Map<String, MedicationEffectCount> byName = tally.byMedication(
          <Attack>[
            attack(medication: 'Sumatriptan', effect: MedicationEffect.helped),
            attack(medication: 'Naproxen'),
            attack(),
          ],
        );

        expect(byName.keys, <String>['Sumatriptan']);
        expect(byName['Sumatriptan']!.helped, 1);
      });

      test('is empty when nothing has been answered', () {
        expect(
          tally.byMedication(<Attack>[attack(medication: 'Naproxen')]),
          isEmpty,
        );
      });
    });
  });

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
