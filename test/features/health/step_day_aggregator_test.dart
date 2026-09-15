import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_sample.dart';
import 'package:migraine_tracker/features/health/domain/services/step_day_aggregator.dart';

StepSample sample(DateTime start, int count) => StepSample(
  start: start,
  end: start.add(const Duration(hours: 1)),
  count: count,
);

void main() {
  const StepDayAggregator aggregator = StepDayAggregator();

  test('empty input yields no days', () {
    expect(aggregator.aggregate(const <StepSample>[]), isEmpty);
  });

  test('samples on the same day sum, unlike sleep no merge is applied', () {
    // Phone writes one chunk, watch writes another, same hour — both count.
    final List<StepDay> days = aggregator.aggregate(<StepSample>[
      sample(DateTime(2026, 1, 5, 9), 500),
      sample(DateTime(2026, 1, 5, 9), 300),
    ]);

    expect(days, hasLength(1));
    expect(days.single.count, 800);
  });

  test('samples group by the calendar date of their start', () {
    final List<StepDay> days = aggregator.aggregate(<StepSample>[
      sample(DateTime(2026, 1, 5, 8), 2000),
      sample(DateTime(2026, 1, 5, 18), 3000),
      sample(DateTime(2026, 1, 6, 8), 1500),
    ]);

    expect(days, hasLength(2));
    expect(days.first.date, DateTime(2026, 1, 5));
    expect(days.first.count, 5000);
    expect(days.last.date, DateTime(2026, 1, 6));
    expect(days.last.count, 1500);
  });

  test('days come back oldest first', () {
    final List<StepDay> days = aggregator.aggregate(<StepSample>[
      sample(DateTime(2026, 1, 7), 1000),
      sample(DateTime(2026, 1, 5), 2000),
      sample(DateTime(2026, 1, 6), 1500),
    ]);

    expect(days.map((StepDay d) => d.date).toList(), <DateTime>[
      DateTime(2026, 1, 5),
      DateTime(2026, 1, 6),
      DateTime(2026, 1, 7),
    ]);
  });

  test('a day with no samples is absent, not zero', () {
    final List<StepDay> days = aggregator.aggregate(<StepSample>[
      sample(DateTime(2026, 1, 5), 2000),
      sample(DateTime(2026, 1, 8), 1800),
    ]);

    expect(days, hasLength(2));
    expect(
      days.map((StepDay d) => d.date),
      isNot(contains(DateTime(2026, 1, 7))),
    );
  });

  test('samples arriving out of order still group correctly', () {
    final List<StepDay> days = aggregator.aggregate(<StepSample>[
      sample(DateTime(2026, 1, 6, 20), 500),
      sample(DateTime(2026, 1, 6, 8), 4000),
    ]);

    expect(days, hasLength(1));
    expect(days.single.count, 4500);
  });
}
