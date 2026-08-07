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
      expect(result.attacksAnalyzed, 0);
      expect(result.requiredAttacks, 15);
    });

    test('attacks left unanswered carry nothing to analyse', () {
      final result = engine.analyze(
        attacksWithLevels(List<ExertionLevel?>.filled(5, null)),
      );
      expect(result, isA<ExertionInsufficientData>());
      expect((result as ExertionInsufficientData).attacksAnalyzed, 0);
    });
  });

  group('below the minimum the analysis still runs', () {
    test('a single answered attack reports counts, not a percentage', () {
      final result = engine.analyze(
        attacksWithLevels(const <ExertionLevel?>[ExertionLevel.severe]),
      );
      expect(result, isA<ExertionInsight>());
      result as ExertionInsight;
      expect(result.attacksAnalyzed, 1);
      expect(result.moderateOrSevereCount, 1);
      expect(result.isCountOnly, isTrue);
      expect(result.isPreliminary, isTrue);
    });

    test('one level everywhere is not judged while the sample is count-only', () {
      final result = engine.analyze(
        attacksWithLevels(List.filled(4, ExertionLevel.light)),
      );
      expect(result, isA<ExertionInsight>());
      expect((result as ExertionInsight).isCountOnly, isTrue);
    });

    test('the share appears from 5 attacks, still flagged preliminary', () {
      final levels = <ExertionLevel?>[
        ...List.filled(3, ExertionLevel.severe),
        ...List.filled(2, ExertionLevel.light),
      ];
      final result = engine.analyze(attacksWithLevels(levels));
      result as ExertionInsight;
      expect(result.isCountOnly, isFalse);
      expect(result.isPreliminary, isTrue);
      expect(result.moderateOrSeverePercent, closeTo(60.0, 0.001));
    });

    test('unanswered attacks do not count toward the minimum', () {
      final levels = <ExertionLevel?>[
        ...List.filled(6, ExertionLevel.moderate),
        ...List.filled(4, ExertionLevel.light),
        ...List<ExertionLevel?>.filled(10, null),
      ];
      final result = engine.analyze(attacksWithLevels(levels));
      result as ExertionInsight;
      expect(result.attacksAnalyzed, 10);
      expect(result.isPreliminary, isTrue);
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

    test('a custom minimum keeps a settled sample preliminary', () {
      const strictEngine = ExertionCorrelationEngine(minAttacks: 30);
      final levels = <ExertionLevel?>[
        ...List.filled(9, ExertionLevel.severe),
        ...List.filled(6, ExertionLevel.light),
      ];
      final result = strictEngine.analyze(attacksWithLevels(levels));

      expect(result, isA<ExertionInsight>());
      expect((result as ExertionInsight).isPreliminary, isTrue);
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
