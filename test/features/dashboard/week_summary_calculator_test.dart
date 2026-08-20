import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/dashboard/domain/services/week_summary_calculator.dart';

Attack _attack(DateTime startedAt, {int intensity = 5}) => Attack(
  id: startedAt.toIso8601String(),
  startedAt: startedAt,
  intensity: intensity,
  regions: const <HeadRegion>[HeadRegion.templeL],
);

void main() {
  const calculator = WeekSummaryCalculator();
  // A Wednesday, so "this week" (Mon-Sun) has room on both sides.
  final now = DateTime(2026, 7, 22, 15);

  test('empty input yields a zeroed summary with no average', () {
    final summary = calculator.compute(const [], now: now);

    expect(summary.thisWeekCount, 0);
    expect(summary.lastWeekCount, 0);
    expect(summary.averageIntensity, isNull);
    expect(summary.trend, 0);
  });

  test(
    'buckets attacks into this week vs last week and averages intensity',
    () {
      final summary = calculator.compute([
        _attack(DateTime(2026, 7, 20, 9), intensity: 4), // Mon this week
        _attack(DateTime(2026, 7, 22, 8), intensity: 8), // Wed this week
        _attack(DateTime(2026, 7, 15, 8)), // Wed last week
        _attack(DateTime(2026, 7, 1, 8)), // three weeks ago — ignored
      ], now: now);

      expect(summary.thisWeekCount, 2);
      expect(summary.lastWeekCount, 1);
      expect(summary.averageIntensity, 6); // (4 + 8) / 2
      expect(summary.trend, 1);
    },
  );

  test('trend is negative when this week is quieter than last', () {
    final summary = calculator.compute([
      _attack(DateTime(2026, 7, 13, 9)), // Mon last week
      _attack(DateTime(2026, 7, 14, 9)), // Tue last week
    ], now: now);

    expect(summary.thisWeekCount, 0);
    expect(summary.lastWeekCount, 2);
    expect(summary.trend, -2);
    expect(summary.averageIntensity, isNull);
  });

  test('week boundary uses local Monday midnight, not a rolling 7 days', () {
    // The Monday that starts "this week" belongs to this week; the Sunday
    // just before it belongs to last week.
    final summary = calculator.compute([
      _attack(DateTime(2026, 7, 20)), // Mon 00:00 — this week
      _attack(DateTime(2026, 7, 19, 23, 59)), // Sun 23:59 — last week
    ], now: now);

    expect(summary.thisWeekCount, 1);
    expect(summary.lastWeekCount, 1);
  });
}
