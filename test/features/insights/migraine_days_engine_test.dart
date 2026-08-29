import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/insights/domain/entities/migraine_days_summary.dart';
import 'package:migraine_tracker/features/insights/domain/services/migraine_days_engine.dart';

int _nextId = 0;

/// [at] is a LOCAL wall-clock time; the entity stores it as UTC, which is exactly the round trip the engine has to undo.
Attack attackAt(DateTime at) => Attack(
  id: 'a${_nextId++}',
  startedAt: at,
  intensity: 5,
  regions: const <HeadRegion>[HeadRegion.templeL],
);

void main() {
  const MigraineDaysEngine engine = MigraineDaysEngine();
  final DateTime now = DateTime(2026, 8, 26, 10);

  setUp(() => _nextId = 0);

  test('an empty history is six months of zero, not an empty list', () {
    final MigraineDaysSummary summary = engine.analyze(
      <Attack>[],
      now: now,
    );

    expect(summary.months, hasLength(6));
    expect(summary.months.every((m) => m.days == 0), isTrue);
    expect(summary.currentMonth!.month, DateTime(2026, 8));
  });

  test('months run oldest first and end on the month of now', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[], now: now);

    expect(summary.months.first.month, DateTime(2026, 3));
    expect(summary.months.last.month, DateTime(2026, 8));
  });

  test('several attacks in one day count as one migraine day', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(DateTime(2026, 8, 4, 7)),
      attackAt(DateTime(2026, 8, 4, 15)),
      attackAt(DateTime(2026, 8, 4, 22)),
    ], now: now);

    expect(summary.currentMonth!.days, 1);
    expect(summary.currentMonth!.attacks, 3);
  });

  test('attacks on separate days each count', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(DateTime(2026, 8, 4, 7)),
      attackAt(DateTime(2026, 8, 9, 7)),
      attackAt(DateTime(2026, 8, 21, 7)),
    ], now: now);

    expect(summary.currentMonth!.days, 3);
  });

  test('a quiet month stays in the window as a zero', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(DateTime(2026, 6, 4, 7)),
      attackAt(DateTime(2026, 8, 4, 7)),
    ], now: now);

    expect(summary.months.map((m) => m.days), <int>[0, 0, 0, 1, 0, 1]);
  });

  test('history older than the window is left out', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(DateTime(2025, 12, 4, 7)),
      attackAt(DateTime(2026, 2, 27, 7)),
    ], now: now);

    expect(summary.months.every((m) => m.days == 0), isTrue);
  });

  group('the month-on-month change', () {
    test('is null while there is nothing to compare against', () {
      const MigraineDaysEngine oneMonth = MigraineDaysEngine(months: 1);

      expect(
        oneMonth.analyze(<Attack>[], now: now).changeFromPreviousMonth,
        isNull,
      );
    });

    test('is negative when this month is running lighter', () {
      final MigraineDaysSummary summary = engine.analyze(<Attack>[
        attackAt(DateTime(2026, 7, 2, 7)),
        attackAt(DateTime(2026, 7, 9, 7)),
        attackAt(DateTime(2026, 7, 20, 7)),
        attackAt(DateTime(2026, 8, 3, 7)),
      ], now: now);

      expect(summary.previousMonth!.days, 3);
      expect(summary.currentMonth!.days, 1);
      expect(summary.changeFromPreviousMonth, -2);
    });

    test('is positive when it is running heavier', () {
      final MigraineDaysSummary summary = engine.analyze(<Attack>[
        attackAt(DateTime(2026, 7, 2, 7)),
        attackAt(DateTime(2026, 8, 3, 7)),
        attackAt(DateTime(2026, 8, 11, 7)),
      ], now: now);

      expect(summary.changeFromPreviousMonth, 1);
    });
  });

  test('the peak is what a y-axis has to reach', () {
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(DateTime(2026, 5, 2, 7)),
      attackAt(DateTime(2026, 5, 9, 7)),
      attackAt(DateTime(2026, 8, 3, 7)),
    ], now: now);

    expect(summary.peakDays, 2);
  });

  test('an empty summary answers without throwing', () {
    const MigraineDaysSummary summary = MigraineDaysSummary.empty();

    expect(summary.currentMonth, isNull);
    expect(summary.previousMonth, isNull);
    expect(summary.changeFromPreviousMonth, isNull);
    expect(summary.peakDays, 0);
  });

  // A late-evening attack is stored as the next UTC day for anyone east of Greenwich.
  test('a late-night attack stays in the local month it happened in', () {
    final DateTime lastEvening = DateTime(2026, 7, 31, 23, 30);
    final MigraineDaysSummary summary = engine.analyze(<Attack>[
      attackAt(lastEvening),
    ], now: now);

    final MonthlyMigraineDays july = summary.months.firstWhere(
      (m) => m.month == DateTime(2026, 7),
    );

    expect(july.days, 1);
    expect(summary.currentMonth!.days, 0);
  });
}
