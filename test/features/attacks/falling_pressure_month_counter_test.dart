import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/services/falling_pressure_month_counter.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

/// The saved step's one personal line: this month's attacks on a falling-pressure day, the saved one included — and nothing at all when the saved attack was not one of them.
void main() {
  const FallingPressureMonthCounter counter = FallingPressureMonthCounter();

  Attack attack(String id, DateTime local, {double? delta}) => Attack(
    id: id,
    startedAt: local.toUtc(),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
    weather: delta == null
        ? null
        : WeatherSnapshot(
            capturedAt: local.toUtc(),
            pressureHpa: 1006.4,
            pressureDelta24hHpa: delta,
          ),
  );

  test('no reading on the saved attack, no line', () {
    final Attack saved = attack('s', DateTime(2026, 9, 29, 14));

    expect(counter.count(saved, <Attack>[saved]), isNull);
  });

  test('a steady or rising day says nothing about falling days', () {
    expect(
      counter.count(attack('s', DateTime(2026, 9, 29, 14), delta: -0.6), []),
      isNull,
    );
    expect(
      counter.count(attack('s', DateTime(2026, 9, 29, 14), delta: 2.3), []),
      isNull,
    );
  });

  test('the first falling-day attack of the month counts as one', () {
    final Attack saved = attack('s', DateTime(2026, 9, 29, 14), delta: -6.8);

    expect(counter.count(saved, <Attack>[saved]), 1);
  });

  test('counts this month only, falling days only, the saved one once', () {
    final Attack saved = attack('s', DateTime(2026, 9, 29, 14), delta: -6.8);
    final List<Attack> all = <Attack>[
      saved,
      attack('a', DateTime(2026, 9, 26, 8), delta: -4.1),
      attack('b', DateTime(2026, 9, 23, 21), delta: -7.4),
      // Steady and rising this month: not counted.
      attack('c', DateTime(2026, 9, 14, 16), delta: -0.6),
      attack('d', DateTime(2026, 9, 10, 7), delta: 2.3),
      // Falling, but last month.
      attack('e', DateTime(2026, 8, 30, 9), delta: -9),
      // No reading: not counted.
      attack('f', DateTime(2026, 9, 2, 9)),
    ];

    expect(counter.count(saved, all), 3);
  });

  test('the saved attack counts even before the stream has it', () {
    final Attack saved = attack('s', DateTime(2026, 9, 29, 14), delta: -6.8);

    expect(
      counter.count(saved, <Attack>[
        attack('a', DateTime(2026, 9, 26, 8), delta: -4.1),
      ]),
      2,
    );
  });

  test('exactly the threshold is falling', () {
    final Attack saved = attack('s', DateTime(2026, 9, 29, 14), delta: -1);

    expect(counter.count(saved, <Attack>[saved]), 1);
  });
}
