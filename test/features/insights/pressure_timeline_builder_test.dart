import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/insights/domain/entities/pressure_timeline.dart';
import 'package:migraine_tracker/features/insights/domain/services/pressure_timeline_builder.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

int _nextId = 0;

Attack attackAt(DateTime at, {int intensity = 5, double? snapshotHpa}) =>
    Attack(
      id: 'a${_nextId++}',
      startedAt: at,
      intensity: intensity,
      regions: const <HeadRegion>[HeadRegion.templeL],
      weather: snapshotHpa == null
          ? null
          : WeatherSnapshot(
              capturedAt: at,
              pressureHpa: snapshotHpa,
              pressureDelta24hHpa: -3,
            ),
    );

DailyPressure reading(DateTime day, {double hpa = 1010, double delta = 0}) =>
    DailyPressure(day: day, pressureHpa: hpa, pressureDelta24hHpa: delta);

void main() {
  const PressureTimelineBuilder builder = PressureTimelineBuilder();
  final DateTime now = DateTime(2026, 8, 26, 10);

  setUp(() => _nextId = 0);

  test('no readings is an empty timeline, not a flat line', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[attackAt(DateTime(2026, 8, 20, 9))],
      readings: const <DailyPressure>[],
      now: now,
    );

    expect(timeline.isEmpty, isTrue);
    expect(timeline.minPressureHpa, isNull);
    expect(timeline.maxPressureHpa, isNull);
  });

  test('a day with a reading and no attack is still a point on the line', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[reading(DateTime(2026, 8, 20))],
      now: now,
    );

    expect(timeline.days.single.hasAttack, isFalse);
    expect(timeline.days.single.peakIntensity, isNull);
  });

  test('attacks land on the reading for their local day', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[
        attackAt(DateTime(2026, 8, 20, 9), intensity: 4),
        attackAt(DateTime(2026, 8, 20, 21), intensity: 8),
      ],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 19)),
        reading(DateTime(2026, 8, 20)),
      ],
      now: now,
    );

    final PressureTimelineDay day = timeline.days.last;

    expect(day.day, DateTime(2026, 8, 20));
    expect(day.attacks, 2);
    // The worst of the day sizes the marker, so a bad day reads as one.
    expect(day.peakIntensity, 8);
    expect(timeline.days.first.attacks, 0);
  });

  // A drawn point is a claim that a measurement happened.
  test('a day with no reading is a gap, never an interpolation', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 18)),
        reading(DateTime(2026, 8, 21)),
      ],
      now: now,
    );

    expect(timeline.days, hasLength(2));
    expect(timeline.days.map((d) => d.day), <DateTime>[
      DateTime(2026, 8, 18),
      DateTime(2026, 8, 21),
    ]);
  });

  test('attacks on days with no reading are counted, not dropped', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[
        attackAt(DateTime(2026, 8, 20, 9)),
        attackAt(DateTime(2026, 8, 22, 9)),
        attackAt(DateTime(2026, 8, 22, 19)),
      ],
      readings: <DailyPressure>[reading(DateTime(2026, 8, 20))],
      now: now,
    );

    expect(timeline.attacksPlotted, 1);
    expect(timeline.attacksWithoutReading, 2);
  });

  test('anything older than the window is left out on both sides', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[attackAt(DateTime(2026, 6, 1, 9))],
      readings: <DailyPressure>[
        reading(DateTime(2026, 6, 1)),
        reading(DateTime(2026, 8, 20)),
      ],
      now: now,
    );

    expect(timeline.days.single.day, DateTime(2026, 8, 20));
    expect(timeline.attacksWithoutReading, 0);
  });

  test('the first day of the window is inside it', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[reading(DateTime(2026, 7, 28))],
      now: now,
    );

    expect(timeline.days.single.day, DateTime(2026, 7, 28));
  });

  test('readings arrive in any order and come out oldest first', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 22)),
        reading(DateTime(2026, 8, 18)),
        reading(DateTime(2026, 8, 20)),
      ],
      now: now,
    );

    expect(timeline.days.map((d) => d.day.day), <int>[18, 20, 22]);
  });

  test('the extremes are what a y-axis has to span', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 18), hpa: 998.5),
        reading(DateTime(2026, 8, 20), hpa: 1021),
      ],
      now: now,
    );

    expect(timeline.minPressureHpa, 998.5);
    expect(timeline.maxPressureHpa, 1021);
  });

  test('a falling day reports itself as a drop at the threshold', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 20), delta: -6),
        reading(DateTime(2026, 8, 21), delta: -2),
      ],
      now: now,
    );

    expect(timeline.days.first.isDrop(5), isTrue);
    expect(timeline.days.last.isDrop(5), isFalse);
  });

  test('a late-night attack stays on the day it started', () {
    final PressureTimeline timeline = builder.build(
      attacks: <Attack>[attackAt(DateTime(2026, 8, 20, 23, 45))],
      readings: <DailyPressure>[
        reading(DateTime(2026, 8, 20)),
        reading(DateTime(2026, 8, 21)),
      ],
      now: now,
    );

    expect(timeline.days.first.attacks, 1);
    expect(timeline.days.last.attacks, 0);
  });

  group('the stranded count', () {
    // The normal state for a user whose history predates the daily readings.
    test('outweighs the plotted attacks when the readings are young', () {
      final PressureTimeline timeline = builder.build(
        attacks: <Attack>[
          attackAt(DateTime(2026, 8, 12, 9)),
          attackAt(DateTime(2026, 8, 13, 9)),
          attackAt(DateTime(2026, 8, 14, 9)),
          attackAt(DateTime(2026, 8, 25, 9)),
        ],
        readings: <DailyPressure>[reading(DateTime(2026, 8, 25))],
        now: now,
      );

      expect(timeline.attacksPlotted, 1);
      expect(timeline.attacksWithoutReading, 3);
      expect(timeline.strandedOutweighsPlotted, isTrue);
    });

    test('does not outweigh them once the readings have caught up', () {
      final PressureTimeline timeline = builder.build(
        attacks: <Attack>[
          attackAt(DateTime(2026, 8, 20, 9)),
          attackAt(DateTime(2026, 8, 21, 9)),
          attackAt(DateTime(2026, 8, 25, 9)),
        ],
        readings: <DailyPressure>[
          reading(DateTime(2026, 8, 20)),
          reading(DateTime(2026, 8, 21)),
        ],
        now: now,
      );

      expect(timeline.attacksPlotted, 2);
      expect(timeline.attacksWithoutReading, 1);
      expect(timeline.strandedOutweighsPlotted, isFalse);
    });

    test('nothing stranded is never an outweighing', () {
      final PressureTimeline timeline = builder.build(
        attacks: <Attack>[attackAt(DateTime(2026, 8, 20, 9))],
        readings: <DailyPressure>[reading(DateTime(2026, 8, 20))],
        now: now,
      );

      expect(timeline.strandedOutweighsPlotted, isFalse);
    });
  });

  group('the hourly marks', () {
    final DateTime now = DateTime(2026, 9, 10, 12);

    test('an attack with a snapshot is placed at its own hour', () {
      final PressureTimeline timeline = const PressureTimelineBuilder().build(
        attacks: <Attack>[
          attackAt(DateTime(2026, 9, 9, 18), snapshotHpa: 1004.5),
        ],
        readings: <DailyPressure>[
          reading(DateTime(2026, 9, 9), hpa: 1009),
          reading(DateTime(2026, 9, 10), hpa: 1011),
        ],
        now: now,
      );

      expect(timeline.moments, hasLength(1));
      // Day 0 of the drawn line, three quarters of the way through it.
      expect(timeline.moments.single.x, closeTo(0.75, 0.001));
      // The pressure AT the attack, not the day's own reading.
      expect(timeline.moments.single.pressureHpa, 1004.5);
    });

    // An attack logged before snapshots existed, or offline where the backfill never landed, keeps the day's dot and nothing more.
    test('an attack with no snapshot leaves no hourly mark', () {
      final PressureTimeline timeline = const PressureTimelineBuilder().build(
        attacks: <Attack>[attackAt(DateTime(2026, 9, 9, 18))],
        readings: <DailyPressure>[reading(DateTime(2026, 9, 9))],
        now: now,
      );

      expect(timeline.moments, isEmpty);
      expect(timeline.days.single.hasAttack, isTrue);
    });

    // The x is a position on the DRAWN line, so it has to survive readings arriving in any order.
    test('the position follows the sorted line, not the input order', () {
      final PressureTimeline timeline = const PressureTimelineBuilder().build(
        attacks: <Attack>[
          attackAt(DateTime(2026, 9, 10, 0), snapshotHpa: 1000),
        ],
        readings: <DailyPressure>[
          reading(DateTime(2026, 9, 10)),
          reading(DateTime(2026, 9, 9)),
          reading(DateTime(2026, 9, 8)),
        ],
        now: now,
      );

      expect(timeline.days.first.day, DateTime(2026, 9, 8));
      expect(timeline.moments.single.x, closeTo(2, 0.001));
    });
  });
}
