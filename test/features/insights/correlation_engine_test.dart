import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/insights/domain/entities/correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/correlation_engine.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

Attack attack({
  required int index,
  double? pressureDelta,
  DateTime? startedAt,
}) {
  return Attack(
    id: 'attack-$index',
    startedAt: startedAt ?? DateTime.utc(2026, 1, 1).add(Duration(days: index)),
    intensity: 5,
    regions: const <HeadRegion>[HeadRegion.templeL],
    weather: pressureDelta == null
        ? null
        : WeatherSnapshot(
            capturedAt: (startedAt ?? DateTime.utc(2026, 1, 1)).add(
              Duration(days: index),
            ),
            pressureHpa: 1013,
            pressureDelta24hHpa: pressureDelta,
          ),
  );
}

/// [deltas] one 24h pressure delta per attack; null = no snapshot (offline).
List<Attack> attacksWithDeltas(List<double?> deltas) => [
  for (final (i, delta) in deltas.indexed)
    attack(index: i, pressureDelta: delta),
];

void main() {
  const engine = CorrelationEngine();

  group('insufficient data', () {
    test('empty history', () {
      final result = engine.analyze([]);
      expect(result, isA<CorrelationInsufficientData>());
      result as CorrelationInsufficientData;
      expect(result.attacksAnalyzed, 0);
      expect(result.requiredAttacks, 15);
    });

    test('attacks logged offline carry no weather, so nothing is analyzed', () {
      final result = engine.analyze(
        attacksWithDeltas(List<double?>.filled(5, null)),
      );
      expect(result, isA<CorrelationInsufficientData>());
      expect((result as CorrelationInsufficientData).attacksAnalyzed, 0);
    });
  });

  group('below the minimum the analysis still runs', () {
    test('a single attack reports counts, not a percentage', () {
      final result = engine.analyze(attacksWithDeltas([-7.0]));
      expect(result, isA<CorrelationInsight>());
      result as CorrelationInsight;
      expect(result.attacksAnalyzed, 1);
      expect(result.attacksDuringPressureDrop, 1);
      expect(result.isCountOnly, isTrue);
      expect(result.isPreliminary, isTrue);
    });

    test('flat weather is not judged while the sample is count-only', () {
      // The same 4 identical deltas would be "no variation" at a larger n.
      final result = engine.analyze(attacksWithDeltas(List.filled(4, -6.0)));
      expect(result, isA<CorrelationInsight>());
      expect((result as CorrelationInsight).isCountOnly, isTrue);
    });

    test('the share appears from 5 attacks, still flagged preliminary', () {
      final deltas = <double?>[...List.filled(3, -7.0), ...List.filled(2, 2.0)];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.isCountOnly, isFalse);
      expect(result.isPreliminary, isTrue);
      expect(result.dropSharePercent, closeTo(60.0, 0.001));
    });

    test('14 attacks is one short of settled', () {
      final deltas = <double?>[...List.filled(8, -7.0), ...List.filled(6, 2.0)];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksAnalyzed, 14);
      expect(result.isPreliminary, isTrue);
    });

    test('attacks without snapshots do not count toward the minimum', () {
      // 20 attacks logged, but only 10 have weather (offline logging).
      final deltas = <double?>[
        ...List.filled(6, -6.0),
        ...List.filled(4, 2.0),
        ...List<double?>.filled(10, null),
      ];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksAnalyzed, 10);
      expect(result.isPreliminary, isTrue);
    });
  });

  group('no weather variation', () {
    test('identical deltas across all attacks carry no signal', () {
      final result = engine.analyze(attacksWithDeltas(List.filled(20, -6.0)));
      expect(result, isA<CorrelationNoVariation>());
      expect((result as CorrelationNoVariation).attacksAnalyzed, 20);
    });

    test('deltas within the 0.5 hPa epsilon still count as flat', () {
      final deltas = List.generate(15, (i) => -6.0 + (i % 2) * 0.4);
      final result = engine.analyze(attacksWithDeltas(deltas));
      expect(result, isA<CorrelationNoVariation>());
    });
  });

  group('insight', () {
    test('computes drop share at exactly the 15-attack minimum', () {
      // 9 rapid drops, 6 stable days.
      final deltas = <double?>[...List.filled(9, -7.0), ...List.filled(6, 2.0)];
      final result = engine.analyze(attacksWithDeltas(deltas));
      expect(result, isA<CorrelationInsight>());
      result as CorrelationInsight;
      expect(result.attacksAnalyzed, 15);
      expect(result.attacksDuringPressureDrop, 9);
      expect(result.dropSharePercent, closeTo(60.0, 0.001));
      expect(result.isPreliminary, isFalse);
      expect(result.isCountOnly, isFalse);
    });

    test('a drop of exactly the threshold counts; just under does not', () {
      final deltas = <double?>[
        -5.0, // exactly at threshold → counts
        -4.99, // just under → does not count
        ...List.filled(13, 3.0),
      ];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksDuringPressureDrop, 1);
    });

    test('rising pressure never counts as a drop', () {
      final deltas = <double?>[
        ...List.filled(10, 6.0), // rapid rise
        ...List.filled(5, -6.0),
      ];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksDuringPressureDrop, 5);
    });

    test('respects a custom user-tuned threshold', () {
      const strictEngine = CorrelationEngine(dropThresholdHpa: 10);
      final deltas = <double?>[
        ...List.filled(8, -7.0), // drop for default, not for strict
        ...List.filled(7, -12.0),
      ];
      final result = strictEngine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksDuringPressureDrop, 7);
    });

    test('attacks without snapshots are excluded from the analysis', () {
      final deltas = <double?>[
        ...List.filled(10, -7.0),
        ...List.filled(5, 2.0),
        ...List<double?>.filled(5, null), // offline logs, no weather yet
      ];
      final result = engine.analyze(attacksWithDeltas(deltas));
      result as CorrelationInsight;
      expect(result.attacksAnalyzed, 15);
      expect(result.attacksDuringPressureDrop, 10);
    });
  });

  group('timezone handling', () {
    test('local and UTC DateTimes for the same instants agree', () {
      final utcResult = engine.analyze([
        for (var i = 0; i < 15; i++)
          attack(
            index: i,
            pressureDelta: i < 9 ? -8.0 : 1.0,
            startedAt: DateTime.utc(2026, 3, 8, 12).add(Duration(days: i)),
          ),
      ]);
      // Same instants expressed as local wall-clock time (crosses the US DST shift on 2026-03-08).
      final localResult = engine.analyze([
        for (var i = 0; i < 15; i++)
          attack(
            index: i,
            pressureDelta: i < 9 ? -8.0 : 1.0,
            startedAt: DateTime.utc(
              2026,
              3,
              8,
              12,
            ).add(Duration(days: i)).toLocal(),
          ),
      ]);

      utcResult as CorrelationInsight;
      localResult as CorrelationInsight;
      expect(
        localResult.attacksDuringPressureDrop,
        utcResult.attacksDuringPressureDrop,
      );
      expect(localResult.attacksAnalyzed, utcResult.attacksAnalyzed);
    });

    test('Attack normalizes startedAt to UTC', () {
      final local = DateTime(2026, 6, 1, 9, 30);
      final a = attack(index: 0, startedAt: local);
      expect(a.startedAt.isUtc, isTrue);
      expect(a.startedAt, local.toUtc());
    });
  });

  group('model invariants', () {
    test('intensity outside 1..10 is rejected', () {
      expect(
        () => Attack(
          id: 'bad',
          startedAt: DateTime.utc(2026),
          intensity: 11,
          regions: const <HeadRegion>[HeadRegion.foreheadL],
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Attack(
          id: 'bad',
          startedAt: DateTime.utc(2026),
          intensity: 0,
          regions: const <HeadRegion>[HeadRegion.foreheadL],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
