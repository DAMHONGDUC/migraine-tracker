import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/home_widget/domain/entities/home_widget_snapshot.dart';
import 'package:migraine_tracker/features/home_widget/domain/enums/pressure_trend.dart';
import 'package:migraine_tracker/features/home_widget/domain/services/home_widget_snapshot_builder.dart';
import 'package:migraine_tracker/features/weather/domain/entities/daily_pressure.dart';

Attack _attack(DateTime startedAt) => Attack(
  id: startedAt.toIso8601String(),
  startedAt: startedAt,
  intensity: 5,
  regions: const <HeadRegion>[HeadRegion.templeL],
);

DailyPressure _reading(DateTime day, {double hpa = 1010, double delta = 0}) =>
    DailyPressure(day: day, pressureHpa: hpa, pressureDelta24hHpa: delta);

void main() {
  const HomeWidgetSnapshotBuilder builder = HomeWidgetSnapshotBuilder();
  // A Wednesday, so "this week" (Mon-Sun) has room on both sides.
  final DateTime now = DateTime(2026, 7, 22, 15);

  test('counts only this week, and reports no pressure without a reading', () {
    final HomeWidgetSnapshot snapshot = builder.build(
      attacks: <Attack>[
        _attack(DateTime(2026, 7, 20, 9)), // Mon this week
        _attack(DateTime(2026, 7, 22, 8)), // Wed this week
        _attack(DateTime(2026, 7, 15, 8)), // last week — not counted
      ],
      pressure: null,
      now: now,
    );

    expect(snapshot.weekCount, 2);
    expect(snapshot.hasPressure, isFalse);
    expect(snapshot.pressureExpiresAt, isNull);
    expect(snapshot.trend, PressureTrend.unknown);
  });

  test("today's reading is shown, and expires at the end of tomorrow", () {
    final HomeWidgetSnapshot snapshot = builder.build(
      attacks: const <Attack>[],
      pressure: _reading(now, hpa: 1002.4, delta: -6.1),
      now: now,
    );

    expect(snapshot.pressureHpa, 1002.4);
    expect(snapshot.pressureDelta24hHpa, -6.1);
    expect(snapshot.pressureExpiresAt, DateTime(2026, 7, 24));
    expect(snapshot.trend, PressureTrend.falling);
  });

  test("yesterday's reading still stands for now", () {
    final HomeWidgetSnapshot snapshot = builder.build(
      attacks: const <Attack>[],
      pressure: _reading(DateTime(2026, 7, 21), delta: 3),
      now: now,
    );

    expect(snapshot.hasPressure, isTrue);
    expect(snapshot.trend, PressureTrend.rising);
  });

  test('a reading two days old is dropped rather than shown as current', () {
    final HomeWidgetSnapshot snapshot = builder.build(
      attacks: const <Attack>[],
      pressure: _reading(DateTime(2026, 7, 20), delta: -8),
      now: now,
    );

    expect(snapshot.hasPressure, isFalse);
    expect(snapshot.pressureDelta24hHpa, isNull);
    expect(snapshot.pressureExpiresAt, isNull);
    expect(snapshot.trend, PressureTrend.unknown);
  });

  test('a change under the threshold reads as steady, not as a direction', () {
    final HomeWidgetSnapshot snapshot = builder.build(
      attacks: const <Attack>[],
      pressure: _reading(now, delta: -0.4),
      now: now,
    );

    expect(snapshot.trend, PressureTrend.steady);
  });
}
