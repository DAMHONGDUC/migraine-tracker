import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_hour.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_sample.dart';
import 'package:migraine_tracker/features/health/domain/services/step_hour_aggregator.dart';

void main() {
  const StepHourAggregator aggregator = StepHourAggregator();

  StepSample sample(int hour, int minute, int count) => StepSample(
    start: DateTime(2026, 8, 11, hour, minute),
    end: DateTime(2026, 8, 11, hour, minute + 5),
    count: count,
  );

  test('sums every sample that starts in the same hour', () {
    final List<StepHour> hours = aggregator.aggregate(<StepSample>[
      sample(9, 0, 100),
      sample(9, 30, 250),
    ]);

    expect(hours, hasLength(1));
    expect(hours.single.count, 350);
    expect(hours.single.hour, DateTime(2026, 8, 11, 9));
  });

  test('orders oldest first whatever order the samples arrive in', () {
    final List<StepHour> hours = aggregator.aggregate(<StepSample>[
      sample(14, 0, 10),
      sample(8, 0, 20),
      sample(11, 0, 30),
    ]);

    expect(hours.map((StepHour h) => h.hour.hour), <int>[8, 11, 14]);
  });

  test('an hour with no samples is absent, not zero', () {
    final List<StepHour> hours = aggregator.aggregate(<StepSample>[
      sample(8, 0, 10),
      sample(10, 0, 10),
    ]);

    // 09:00 had no record, which is not the same as no steps.
    expect(hours, hasLength(2));
    expect(hours.map((StepHour h) => h.hour.hour), <int>[8, 10]);
  });

  test('credits a sample to the hour it starts in', () {
    final List<StepHour> hours = aggregator.aggregate(<StepSample>[
      StepSample(
        start: DateTime(2026, 8, 11, 9, 50),
        end: DateTime(2026, 8, 11, 10, 20),
        count: 600,
      ),
    ]);

    // Splitting it would need a distribution HealthKit does not report.
    expect(hours.single.hour.hour, 9);
    expect(hours.single.count, 600);
  });

  test('no samples means no bars', () {
    expect(aggregator.aggregate(<StepSample>[]), isEmpty);
  });
}
