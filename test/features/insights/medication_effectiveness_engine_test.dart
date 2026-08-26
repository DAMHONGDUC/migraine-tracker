import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';
import 'package:migraine_tracker/features/insights/domain/entities/medication_effectiveness_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/medication_effectiveness_engine.dart';

Attack attack({
  required int index,
  String? medicationName,
  MedicationEffect? effect,
  int intensity = 5,
  Duration? lasted,
}) {
  final DateTime startedAt = DateTime.utc(2026, 1, 1).add(Duration(days: index));

  return Attack(
    id: 'attack-$index',
    startedAt: startedAt,
    intensity: intensity,
    regions: const <HeadRegion>[HeadRegion.templeL],
    medicationName: medicationName,
    medicationEffect: effect,
    endedAt: lasted == null ? null : startedAt.add(lasted),
  );
}

/// [effects] one answer per dose of [name]; null = taken, never answered.
List<Attack> doses(
  String name,
  List<MedicationEffect?> effects, {
  int startIndex = 0,
}) => <Attack>[
  for (final (int i, MedicationEffect? effect) in effects.indexed)
    attack(index: startIndex + i, medicationName: name, effect: effect),
];

void main() {
  const MedicationEffectivenessEngine engine = MedicationEffectivenessEngine();

  group('insufficient data', () {
    test('empty history', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[]);

      expect(result, isA<MedicationEffectivenessInsufficientData>());
      result as MedicationEffectivenessInsufficientData;
      expect(result.answeredAttacks, 0);
      expect(result.timesTaken, 0);
      expect(result.requiredAnswers, 10);
    });

    test('attacks logged without a medication carry nothing to rank', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        attack(index: 0),
        attack(index: 1, medicationName: '  '),
      ]);

      expect(result, isA<MedicationEffectivenessInsufficientData>());
      expect(
        (result as MedicationEffectivenessInsufficientData).timesTaken,
        0,
      );
    });

    test('taken but never followed up separates from never taken', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses('Sumatriptan', List<MedicationEffect?>.filled(6, null)),
      );

      expect(result, isA<MedicationEffectivenessInsufficientData>());
      result as MedicationEffectivenessInsufficientData;
      expect(result.answeredAttacks, 0);
      expect(result.timesTaken, 6);
    });
  });

  group('one medication', () {
    test('counts every answer and the doses left unanswered', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses('Sumatriptan', <MedicationEffect?>[
          MedicationEffect.helped,
          MedicationEffect.helped,
          MedicationEffect.partly,
          MedicationEffect.didNotHelp,
          null,
        ]),
      );

      expect(result, isA<MedicationEffectivenessInsight>());
      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.name, 'Sumatriptan');
      expect(row.timesTaken, 5);
      expect(row.helpedCount, 2);
      expect(row.partlyCount, 1);
      expect(row.didNotHelpCount, 1);
      expect(row.answeredCount, 4);
      expect(row.unansweredCount, 1);
      expect(row.anyReliefCount, 3);
    });

    test('a thin sample stays counts, never a percentage', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses('Ibuprofen', <MedicationEffect?>[
          MedicationEffect.helped,
          MedicationEffect.didNotHelp,
        ]),
      );

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.isCountOnly, isTrue);
      expect(result.isPreliminary, isTrue);
    });

    test('five answers earn the percentage', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses('Ibuprofen', <MedicationEffect?>[
          MedicationEffect.helped,
          MedicationEffect.helped,
          MedicationEffect.partly,
          MedicationEffect.didNotHelp,
          MedicationEffect.didNotHelp,
        ]),
      );

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.isCountOnly, isFalse);
      expect(row.helpedPercent, 40);
      expect(row.anyReliefPercent, 60);
    });

    test('ten answers settle the result', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses(
          'Ibuprofen',
          List<MedicationEffect?>.filled(10, MedicationEffect.helped),
        ),
      );

      expect(result.answeredAttacks, 10);
      expect(result.isPreliminary, isFalse);
    });
  });

  group('medians', () {
    test('intensity is taken over every dose, answered or not', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        attack(
          index: 0,
          medicationName: 'Rizatriptan',
          effect: MedicationEffect.helped,
          intensity: 4,
        ),
        attack(index: 1, medicationName: 'Rizatriptan', intensity: 8),
        attack(index: 2, medicationName: 'Rizatriptan', intensity: 6),
      ]);

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.medianIntensity, 6);
    });

    test('an even count averages the two middles', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        attack(
          index: 0,
          medicationName: 'Rizatriptan',
          effect: MedicationEffect.helped,
          intensity: 4,
        ),
        attack(index: 1, medicationName: 'Rizatriptan', intensity: 7),
      ]);

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.medianIntensity, 5.5);
    });

    test('duration counts only the attacks whose end was recorded', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        attack(
          index: 0,
          medicationName: 'Rizatriptan',
          effect: MedicationEffect.helped,
          lasted: const Duration(hours: 2),
        ),
        attack(
          index: 1,
          medicationName: 'Rizatriptan',
          effect: MedicationEffect.helped,
          lasted: const Duration(hours: 4),
        ),
        attack(
          index: 2,
          medicationName: 'Rizatriptan',
          effect: MedicationEffect.helped,
        ),
      ]);

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.medianDuration, const Duration(hours: 3));
    });

    test('no recorded end leaves the duration null, never zero', () {
      final MedicationEffectivenessResult result = engine.analyze(
        doses('Rizatriptan', <MedicationEffect?>[MedicationEffect.helped]),
      );

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.medianDuration, isNull);
    });

    test('one outlying attack does not drag the median', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        for (final (int i, Duration lasted) in <Duration>[
          const Duration(hours: 3),
          const Duration(hours: 3),
          const Duration(hours: 30),
        ].indexed)
          attack(
            index: i,
            medicationName: 'Rizatriptan',
            effect: MedicationEffect.helped,
            lasted: lasted,
          ),
      ]);

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.medianDuration, const Duration(hours: 3));
    });
  });

  group('several medications', () {
    test('most-used first, never by relief rate', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        ...doses('Sumatriptan', <MedicationEffect?>[
          MedicationEffect.partly,
          MedicationEffect.partly,
          MedicationEffect.helped,
        ]),
        ...doses('Aspirin', <MedicationEffect?>[
          MedicationEffect.helped,
        ], startIndex: 3),
      ]);

      final List<MedicationEffectiveness> rows =
          (result as MedicationEffectivenessInsight).medications;

      // Aspirin is 100% helped off one dose and still comes second.
      expect(rows.map((r) => r.name), <String>['Sumatriptan', 'Aspirin']);
      expect(result.answeredAttacks, 4);
    });

    test('a tie between two medications sorts by name', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        ...doses('Zolmitriptan', <MedicationEffect?>[MedicationEffect.helped]),
        ...doses(
          'Aspirin',
          <MedicationEffect?>[MedicationEffect.helped],
          startIndex: 1,
        ),
      ]);

      final List<MedicationEffectiveness> rows =
          (result as MedicationEffectivenessInsight).medications;

      expect(rows.map((r) => r.name), <String>['Aspirin', 'Zolmitriptan']);
    });

    test("another medication's outcomes never leak in", () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        ...doses('Sumatriptan', <MedicationEffect?>[MedicationEffect.helped]),
        ...doses(
          'Ibuprofen',
          <MedicationEffect?>[MedicationEffect.didNotHelp],
          startIndex: 1,
        ),
      ]);

      final List<MedicationEffectiveness> rows =
          (result as MedicationEffectivenessInsight).medications;

      expect(rows.firstWhere((r) => r.name == 'Sumatriptan').didNotHelpCount, 0);
      expect(rows.firstWhere((r) => r.name == 'Ibuprofen').helpedCount, 0);
    });

    // The surfaces drop these rows rather than print "0/0", so the engine has
    // to keep them distinguishable instead of guessing on their behalf.
    test('a medication nobody answered for is a row with no answers', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        ...doses('Sumatriptan', <MedicationEffect?>[MedicationEffect.helped]),
        ...doses('Naproxen', <MedicationEffect?>[null], startIndex: 1),
      ]);

      final MedicationEffectiveness row = (result
              as MedicationEffectivenessInsight)
          .medications
          .firstWhere((r) => r.name == 'Naproxen');

      expect(row.answeredCount, 0);
      expect(row.unansweredCount, 1);
      expect(row.timesTaken, 1);
    });

    test('the same medication logged with stray spacing is one row', () {
      final MedicationEffectivenessResult result = engine.analyze(<Attack>[
        attack(
          index: 0,
          medicationName: 'Naproxen',
          effect: MedicationEffect.helped,
        ),
        attack(
          index: 1,
          medicationName: '  Naproxen  ',
          effect: MedicationEffect.partly,
        ),
      ]);

      final MedicationEffectiveness row =
          (result as MedicationEffectivenessInsight).medications.single;

      expect(row.name, 'Naproxen');
      expect(row.timesTaken, 2);
    });
  });
}
