import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/insights/domain/entities/exertion_correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/exertion_correlation_engine.dart';

Attack attack({required int index, ExertionLevel? exertionLevel}) {
  return Attack(
    id: 'attack-$index',
    startedAt: DateTime.utc(2026, 1, 1).add(Duration(days: index)),
    intensity: 5,
    location: HeadLocation.left,
    exertionLevel: exertionLevel,
  );
}

/// [levels] one exertion level per attack; null = not answered.
List<Attack> attacksWithLevels(List<ExertionLevel?> levels) => [
  for (final (i, level) in levels.indexed) attack(index: i, exertionLevel: level),
];

void main() {
  const engine = ExertionCorrelationEngine();

  group('insufficient data', () {
    test('empty history', () {
      final result = engine.analyze([]);
      expect(result, isA<ExertionInsufficientData>());
      result as ExertionInsufficientData;
      expect(result.attacksWithExertion, 0);
      expect(result.requiredAttacks, 15);
    });

    test('14 attacks with exertion is one short of the minimum', () {
      final result = engine.analyze(
        attacksWithLevels(List.filled(14, ExertionLevel.light)),
      );
      expect(result, isA<ExertionInsufficientData>());
      expect(
        (result as ExertionInsufficientData).attacksWithExertion,
        14,
      );
    });

    test('attacks left unanswered do not count toward the minimum', () {
      // 20 attacks logged, but only 10 have an exertion answer.
      final levels = <ExertionLevel?>[
        ...List.filled(10, ExertionLevel.moderate),
        ...List<ExertionLevel?>.filled(10, null),
      ];
      final result = engine.analyze(attacksWithLevels(levels));
      expect(result, isA<ExertionInsufficientData>());
      expect((result as ExertionInsufficientData).attacksWithExertion, 10);
    });
  });

  group('no variation', () {
    test('every answered attack reporting the same level carries no signal', () {
      final result = engine.analyze(
        attacksWithLevels(List.filled(20, ExertionLevel.moderate)),
      );
      expect(result, isA<ExertionNoVariation>());
      expect((result as ExertionNoVariation).attacksAnalyzed, 20);
    });
  });

  group('insight', () {
    test('computes the moderate-or-severe share and per-level counts', () {
      final levels = <ExertionLevel?>[
        ...List.filled(5, ExertionLevel.light),
        ...List.filled(6, ExertionLevel.moderate),
        ...List.filled(4, ExertionLevel.severe),
      ];
      final result = engine.analyze(attacksWithLevels(levels));
      expect(result, isA<ExertionInsight>());
      result as ExertionInsight;
      expect(result.attacksAnalyzed, 15);
      expect(result.lightCount, 5);
      expect(result.moderateCount, 6);
      expect(result.severeCount, 4);
      expect(result.moderateOrSeverePercent, closeTo(66.667, 0.01));
    });

    test('unanswered attacks are excluded from the analysis', () {
      final levels = <ExertionLevel?>[
        ...List.filled(9, ExertionLevel.severe),
        ...List.filled(6, ExertionLevel.light),
        ...List<ExertionLevel?>.filled(5, null),
      ];
      final result = engine.analyze(attacksWithLevels(levels));
      result as ExertionInsight;
      expect(result.attacksAnalyzed, 15);
      expect(result.severeCount, 9);
      expect(result.lightCount, 6);
    });

    test('respects a custom user-tuned minimum', () {
      const strictEngine = ExertionCorrelationEngine(minAttacks: 30);
      final levels = <ExertionLevel?>[
        ...List.filled(9, ExertionLevel.severe),
        ...List.filled(6, ExertionLevel.light),
      ];

      expect(
        strictEngine.analyze(attacksWithLevels(levels)),
        isA<ExertionInsufficientData>(),
      );
    });
  });

  group('model invariants', () {
    test('minAttacks must be positive', () {
      expect(
        () => ExertionCorrelationEngine(minAttacks: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
