import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_summary.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_summary.dart';
import 'package:migraine_tracker/features/health/domain/services/health_summariser.dart';

void main() {
  const HealthSummariser summariser = HealthSummariser();

  SleepNight night(int day, Duration slept) =>
      SleepNight(date: DateTime(2026, 8, day), duration: slept);
  StepDay day(int date, int count) =>
      StepDay(date: DateTime(2026, 8, date), count: count);

  group('sleep', () {
    test('averages only the nights that were measured', () {
      final SleepSummary summary = summariser.sleep(<SleepNight>[
        night(1, const Duration(hours: 6)),
        night(3, const Duration(hours: 8)),
      ]);

      // A night with no samples is absent, not zero — averaging over the window instead would report 4h40m for someone who slept fine.
      expect(summary.average, const Duration(hours: 7));
    });

    test('keeps the newest window and takes the latest from its end', () {
      final SleepSummary summary = summariser.sleep(<SleepNight>[
        for (int i = 1; i <= 10; i++) night(i, Duration(hours: i)),
      ]);

      expect(summary.nights, hasLength(HealthSummariser.windowDays));
      expect(summary.nights.first.date.day, 4);
      expect(summary.latest!.duration, const Duration(hours: 10));
    });

    test('nothing read is empty, not a zero-hour night', () {
      final SleepSummary summary = summariser.sleep(const <SleepNight>[]);

      expect(summary.isEmpty, isTrue);
      expect(summary.latest, isNull);
    });
  });

  group('steps', () {
    test('averages only the days that were counted', () {
      final StepSummary summary = summariser.steps(<StepDay>[
        day(1, 4000),
        day(3, 6000),
      ]);

      expect(summary.average, 5000);
    });

    test('keeps the newest window and takes the latest from its end', () {
      final StepSummary summary = summariser.steps(<StepDay>[
        for (int i = 1; i <= 10; i++) day(i, i * 1000),
      ]);

      expect(summary.days, hasLength(HealthSummariser.windowDays));
      expect(summary.latest!.count, 10000);
    });

    test('nothing read is empty', () {
      expect(summariser.steps(const <StepDay>[]).isEmpty, isTrue);
    });
  });
}
