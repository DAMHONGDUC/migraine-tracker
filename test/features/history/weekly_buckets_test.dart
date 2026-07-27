import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/domain/services/weekly_buckets.dart';

Attack attackAt(DateTime startedAt, [int i = 0]) => Attack(
  id: 'a-${startedAt.toIso8601String()}-$i',
  startedAt: startedAt,
  intensity: 5,
  location: HeadLocation.left,
);

void main() {
  // Wednesday 2026-07-08.
  final now = DateTime(2026, 7, 8, 15);
  const calculator = WeeklyBucketsCalculator();

  test('produces the requested number of weeks, oldest first, zero-filled', () {
    final buckets = calculator.compute([], now: now);
    expect(buckets, hasLength(8));
    expect(buckets.last.weekStart, DateTime(2026, 7, 6)); // this Monday
    expect(buckets.first.weekStart, DateTime(2026, 5, 18));
    expect(buckets.every((b) => b.count == 0), isTrue);
  });

  test('counts attacks into their local calendar week (Monday start)', () {
    final buckets = calculator.compute([
      attackAt(DateTime(2026, 7, 6, 0, 30)), // Monday this week
      attackAt(DateTime(2026, 7, 8, 9)), // Wednesday this week
      attackAt(DateTime(2026, 7, 5, 23)), // Sunday → previous week
    ], now: now);

    expect(buckets.last.count, 2);
    expect(buckets[6].count, 1);
  });

  test('attacks older than the window are excluded', () {
    final buckets = calculator.compute([
      attackAt(DateTime(2026, 1, 1)),
    ], now: now);
    expect(buckets.every((b) => b.count == 0), isTrue);
  });

  test('multiple attacks in one week accumulate', () {
    final monday = DateTime(2026, 6, 29);
    final buckets = calculator.compute([
      for (var i = 0; i < 4; i++)
        attackAt(monday.add(Duration(days: i, hours: 8)), i),
    ], now: now);
    expect(buckets[6].weekStart, monday);
    expect(buckets[6].count, 4);
  });
}
