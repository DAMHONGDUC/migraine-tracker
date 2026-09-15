import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_interval.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/services/sleep_night_aggregator.dart';

/// Local wall-clock, which is what HealthKit hands back.
SleepInterval sample(DateTime start, Duration length) =>
    SleepInterval(start: start, end: start.add(length));

void main() {
  const SleepNightAggregator aggregator = SleepNightAggregator();

  group('merging overlapping samples', () {
    test('empty input yields no nights', () {
      expect(aggregator.aggregate(const <SleepInterval>[]), isEmpty);
    });

    test('a stage sample inside an in-bed sample is not counted twice', () {
      // 23:00 → 07:00 in bed, with a 02:00 → 04:00 deep-sleep block inside it.
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 8)),
        sample(DateTime(2026, 1, 6, 2), const Duration(hours: 2)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.duration, const Duration(hours: 8));
    });

    test('partly overlapping samples merge into their union', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 4)),
        sample(DateTime(2026, 1, 6, 1), const Duration(hours: 5)),
      ]);

      // 23:00 → 06:00, not 4h + 5h.
      expect(nights.single.duration, const Duration(hours: 7));
    });

    test('touching samples are one stretch of sleep', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 3)),
        sample(DateTime(2026, 1, 6, 2), const Duration(hours: 4)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.duration, const Duration(hours: 7));
    });

    test('samples arriving out of order still merge', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 6, 2), const Duration(hours: 2)),
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 8)),
      ]);

      expect(nights.single.duration, const Duration(hours: 8));
    });

    test('a gap splits the night into two blocks that still sum', () {
      // Woke at 02:00, back to sleep 03:00 → 07:00.
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 3)),
        sample(DateTime(2026, 1, 6, 3), const Duration(hours: 4)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.duration, const Duration(hours: 7));
    });
  });

  group('which night a block belongs to', () {
    test('a block crossing midnight lands on the morning it ends', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 7)),
      ]);

      expect(nights.single.date, DateTime(2026, 1, 6));
    });

    test('an evening block belongs to the NEXT morning', () {
      // Asleep 21:00 → 23:30 on the 5th: still the night of the 5th→6th.
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 21), const Duration(hours: 2, minutes: 30)),
      ]);

      expect(nights.single.date, DateTime(2026, 1, 6));
    });

    test('a block ending before the cutoff belongs to that same morning', () {
      // An afternoon nap, 14:00 → 15:30 on the 6th.
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 6, 14), const Duration(hours: 1, minutes: 30)),
      ]);

      expect(nights.single.date, DateTime(2026, 1, 6));
    });

    test('an evening block and the sleep it runs into are one night', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 22), const Duration(hours: 1)),
        sample(DateTime(2026, 1, 6, 0), const Duration(hours: 6)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.date, DateTime(2026, 1, 6));
      expect(nights.single.duration, const Duration(hours: 7));
    });

    test('nights come back oldest first, one entry each', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 7, 23), const Duration(hours: 6)),
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 7)),
        sample(DateTime(2026, 1, 6, 23), const Duration(hours: 8)),
      ]);

      expect(nights.map((SleepNight n) => n.date).toList(), <DateTime>[
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
      ]);
    });

    test('a night with no samples is absent, not zero', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(hours: 7)),
        sample(DateTime(2026, 1, 8, 23), const Duration(hours: 7)),
      ]);

      expect(nights, hasLength(2));
      expect(
        nights.map((SleepNight n) => n.date),
        isNot(contains(DateTime(2026, 1, 7))),
      );
    });
  });

  group('noise', () {
    test('a block under the minimum session is dropped', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        sample(DateTime(2026, 1, 5, 23), const Duration(minutes: 5)),
      ]);

      expect(nights, isEmpty);
    });

    test('short fragments that merge into a real block are kept', () {
      final List<SleepNight> nights = aggregator.aggregate(<SleepInterval>[
        for (int i = 0; i < 12; i++)
          sample(
            DateTime(2026, 1, 5, 23).add(Duration(minutes: 5 * i)),
            const Duration(minutes: 5),
          ),
      ]);

      expect(nights.single.duration, const Duration(hours: 1));
    });
  });

  test('SleepNight.hours reads the duration as fractional hours', () {
    final SleepNight night = SleepNight(
      date: DateTime(2026, 1, 6),
      duration: const Duration(hours: 7, minutes: 30),
    );

    expect(night.hours, closeTo(7.5, 0.001));
  });
}
