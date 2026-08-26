import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/insights/domain/entities/medication_overuse_result.dart';
import 'package:migraine_tracker/features/insights/domain/services/medication_overuse_engine.dart';

int _nextId = 0;

Attack attackAt(DateTime at, {String? medication = 'Sumatriptan'}) => Attack(
  id: 'a${_nextId++}',
  startedAt: at,
  intensity: 6,
  regions: const <HeadRegion>[HeadRegion.templeL],
  medicationName: medication,
);

/// [days] days of the given month, one attack each, all medicated.
List<Attack> intakeDays(int year, int month, int days) => <Attack>[
  for (int day = 1; day <= days; day++) attackAt(DateTime(year, month, day, 9)),
];

void main() {
  const MedicationOveruseEngine engine = MedicationOveruseEngine();
  final DateTime now = DateTime(2026, 8, 26, 10);

  setUp(() => _nextId = 0);

  group('counting intake days', () {
    test('an empty history is six quiet months', () {
      final MedicationOveruseResult result = engine.analyze(
        <Attack>[],
        now: now,
      );

      expect(result.months, hasLength(6));
      expect(result.currentMonthDays, 0);
      expect(result.risk, MedicationOveruseRisk.none);
    });

    test('two doses on one day are one intake day', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        attackAt(DateTime(2026, 8, 4, 9)),
        attackAt(DateTime(2026, 8, 4, 18)),
      ], now: now);

      expect(result.currentMonthDays, 1);
    });

    test('an attack logged with no medication is not an intake day', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        attackAt(DateTime(2026, 8, 4, 9), medication: null),
        attackAt(DateTime(2026, 8, 5, 9), medication: '  '),
        attackAt(DateTime(2026, 8, 6, 9)),
      ], now: now);

      expect(result.currentMonthDays, 1);
    });

    test('an evening dose stays in the local month it was taken in', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        attackAt(DateTime(2026, 7, 31, 23, 30)),
      ], now: now);

      expect(result.currentMonthDays, 0);
      expect(
        result.months.firstWhere((m) => m.month == DateTime(2026, 7)).days,
        1,
      );
    });
  });

  group('the risk grade', () {
    test('stays quiet below the warning line', () {
      final MedicationOveruseResult result = engine.analyze(
        intakeDays(2026, 8, 7),
        now: now,
      );

      expect(result.risk, MedicationOveruseRisk.none);
    });

    test('speaks two days before the threshold, not on it', () {
      final MedicationOveruseResult result = engine.analyze(
        intakeDays(2026, 8, 8),
        now: now,
      );

      expect(result.risk, MedicationOveruseRisk.approaching);
    });

    test('is at risk on the threshold itself', () {
      final MedicationOveruseResult result = engine.analyze(
        intakeDays(2026, 8, 10),
        now: now,
      );

      expect(result.risk, MedicationOveruseRisk.atRisk);
      expect(result.thresholdDays, 10);
      expect(result.warnAtDays, 8);
    });
  });

  group('the sustained pattern', () {
    // ICHD-3 needs the pattern held longer than three months; a single heavy
    // month is a bad month, and calling it overuse would be a false alarm.
    test('one heavy month is not the pattern', () {
      final MedicationOveruseResult result = engine.analyze(
        intakeDays(2026, 8, 12),
        now: now,
      );

      expect(result.consecutiveMonthsAtRisk, 1);
      expect(result.isSustained, isFalse);
    });

    test('three months running is', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        ...intakeDays(2026, 6, 11),
        ...intakeDays(2026, 7, 10),
        ...intakeDays(2026, 8, 14),
      ], now: now);

      expect(result.consecutiveMonthsAtRisk, 3);
      expect(result.isSustained, isTrue);
    });

    test('a month under the line breaks the run', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        ...intakeDays(2026, 6, 11),
        ...intakeDays(2026, 7, 4),
        ...intakeDays(2026, 8, 14),
      ], now: now);

      expect(result.consecutiveMonthsAtRisk, 1);
      expect(result.isSustained, isFalse);
    });

    test('a run that ended last month is not counted as current', () {
      final MedicationOveruseResult result = engine.analyze(<Attack>[
        ...intakeDays(2026, 5, 12),
        ...intakeDays(2026, 6, 12),
        ...intakeDays(2026, 7, 12),
        ...intakeDays(2026, 8, 2),
      ], now: now);

      expect(result.consecutiveMonthsAtRisk, 0);
      expect(result.risk, MedicationOveruseRisk.none);
    });
  });
}
