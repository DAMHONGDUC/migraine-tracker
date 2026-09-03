import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/health/domain/entities/cycle_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/cycle_sample.dart';
import 'package:migraine_tracker/features/health/domain/services/cycle_day_aggregator.dart';
import 'package:migraine_tracker/features/health/domain/services/cycle_window_calculator.dart';

void main() {
  const CycleWindowCalculator calculator = CycleWindowCalculator();
  const CycleDayAggregator aggregator = CycleDayAggregator();

  List<CycleDay> cycleStartingOn(DateTime start) => <CycleDay>[
    CycleDay(day: start, hasFlow: true, isPeriodStart: true),
    CycleDay(
      day: start.add(const Duration(days: 1)),
      hasFlow: true,
      isPeriodStart: false,
    ),
  ];

  group('the window', () {
    final DateTime start = DateTime(2026, 9, 5);

    test('the two days before the period are inside it', () {
      expect(
        calculator.dayInCycle(cycleStartingOn(start), DateTime(2026, 9, 3)),
        -2,
      );
    });

    test('the start day itself is day 0', () {
      expect(calculator.dayInCycle(cycleStartingOn(start), start), 0);
    });

    test('the third day after the start is the last one inside', () {
      expect(
        calculator.dayInCycle(cycleStartingOn(start), DateTime(2026, 9, 8)),
        3,
      );
    });

    // Widening the window until most of the month qualifies would make every attack look hormonal.
    test('a day outside the window has no place in it', () {
      expect(
        calculator.dayInCycle(cycleStartingOn(start), DateTime(2026, 9, 9)),
        isNull,
      );
      expect(
        calculator.dayInCycle(cycleStartingOn(start), DateTime(2026, 9, 2)),
        isNull,
      );
    });

    // A day of bleeding is not a start; only HealthKit's own marker is.
    test('a bleeding day that is not a start opens no window', () {
      final List<CycleDay> days = <CycleDay>[
        CycleDay(day: start, hasFlow: true, isPeriodStart: false),
      ];

      expect(calculator.dayInCycle(days, start), isNull);
      expect(calculator.isInWindow(days, start), isFalse);
    });
  });

  group('the aggregator', () {
    test('samples on one local day become one day', () {
      final List<CycleDay> days = aggregator.aggregate(<CycleSample>[
        CycleSample(
          start: DateTime(2026, 9, 5, 7),
          hasFlow: false,
          isPeriodStart: true,
        ),
        CycleSample(
          start: DateTime(2026, 9, 5, 19),
          hasFlow: true,
          isPeriodStart: false,
        ),
      ]);

      expect(days, hasLength(1));
      // Either flag wins: a day with two samples where one says bleeding is a day with bleeding.
      expect(days.single.hasFlow, isTrue);
      expect(days.single.isPeriodStart, isTrue);
    });

    test('days come back oldest first', () {
      final List<CycleDay> days = aggregator.aggregate(<CycleSample>[
        CycleSample(
          start: DateTime(2026, 9, 7),
          hasFlow: true,
          isPeriodStart: false,
        ),
        CycleSample(
          start: DateTime(2026, 9, 5),
          hasFlow: true,
          isPeriodStart: true,
        ),
      ]);

      expect(days.map((CycleDay d) => d.day), <DateTime>[
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 7),
      ]);
    });
  });
}
