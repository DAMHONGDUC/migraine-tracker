import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/insights/domain/enums/health_range.dart';
import 'package:migraine_tracker/features/insights/domain/services/health_range_buckets.dart';

void main() {
  // A Monday, so the weekly grouping's boundaries are unambiguous.
  final DateTime monday = DateTime(2026, 8, 3);

  StepDay steps(int dayOffset, int count) =>
      StepDay(date: monday.add(Duration(days: dayOffset)), count: count);

  SleepNight night(int dayOffset, double hours) => SleepNight(
    date: monday.add(Duration(days: dayOffset)),
    duration: Duration(minutes: (hours * 60).round()),
  );

  group('HealthRangeBuckets.steps', () {
    test('passes days straight through for every range but half a year', () {
      final List<HealthBucket> buckets = HealthRangeBuckets.steps(
        <StepDay>[steps(0, 100), steps(1, 200)],
        HealthRange.month,
      );

      expect(buckets.map((HealthBucket b) => b.value), <double>[100, 200]);
    });

    test('sums into Monday-anchored weeks at half a year', () {
      final List<HealthBucket> buckets = HealthRangeBuckets.steps(
        <StepDay>[
          steps(0, 100), // Mon, week 1
          steps(6, 200), // Sun, still week 1
          steps(7, 50), // Mon, week 2
        ],
        HealthRange.halfYear,
      );

      expect(buckets, hasLength(2));
      expect(buckets.first.start, monday);
      expect(buckets.first.value, 300);
      expect(buckets.last.value, 50);
    });

    test('a week with no data is absent, never a zero bar', () {
      final List<HealthBucket> buckets = HealthRangeBuckets.steps(
        <StepDay>[steps(0, 100), steps(14, 100)],
        HealthRange.halfYear,
      );

      // The week between them had no samples at all — "no record" is not "no steps", so it must not be drawn as a bar on the floor.
      expect(buckets, hasLength(2));
    });
  });

  group('HealthRangeBuckets.sleep', () {
    test('averages a week rather than summing it', () {
      final List<HealthBucket> buckets = HealthRangeBuckets.sleep(
        <SleepNight>[night(0, 6), night(1, 8)],
        HealthRange.halfYear,
      );

      expect(buckets, hasLength(1));
      expect(buckets.single.value, 7);
    });

    test('reports nightly hours untouched on a narrower range', () {
      final List<HealthBucket> buckets = HealthRangeBuckets.sleep(
        <SleepNight>[night(0, 6.5), night(1, 7.25)],
        HealthRange.week,
      );

      expect(buckets.map((HealthBucket b) => b.value), <double>[6.5, 7.25]);
    });
  });

  test('only half a year groups into weeks', () {
    expect(HealthRange.halfYear.isWeekly, isTrue);
    expect(
      HealthRange.values.where((HealthRange r) => r.isWeekly),
      hasLength(1),
    );
  });
}
