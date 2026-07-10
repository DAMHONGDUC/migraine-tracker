import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/domain/enums/history_period.dart';
import 'package:migraine_tracker/features/history/domain/services/attack_period_filter.dart';

Attack at(DateTime local) => Attack(
  id: local.toIso8601String(),
  startedAt: local.toUtc(),
  intensity: 5,
  location: HeadLocation.left,
);

void main() {
  // Wednesday 2026-07-08, 15:00 local.
  final now = DateTime(2026, 7, 8, 15);

  final attacks = [
    at(DateTime(2026, 7, 8, 9)), // today
    at(DateTime(2026, 7, 6, 10)), // Monday this week
    at(DateTime(2026, 7, 5, 23)), // Sunday → last week, this month
    at(DateTime(2026, 6, 20)), // last month, this year
    at(DateTime(2025, 12, 31)), // last year
  ];

  int count(HistoryPeriod p) => filterByPeriod(attacks, p, now).length;

  test('today keeps only attacks on the current calendar day', () {
    expect(count(HistoryPeriod.today), 1);
  });

  test('week keeps Monday..now of the current calendar week', () {
    expect(count(HistoryPeriod.week), 2);
  });

  test('month keeps the current calendar month', () {
    expect(count(HistoryPeriod.month), 3);
  });

  test('year keeps the current calendar year', () {
    expect(count(HistoryPeriod.year), 4);
  });

  test('all keeps everything', () {
    expect(count(HistoryPeriod.all), 5);
  });

  test('periodStart is null only for all', () {
    expect(periodStart(HistoryPeriod.all, now), isNull);
    expect(periodStart(HistoryPeriod.today, now), DateTime(2026, 7, 8));
    expect(periodStart(HistoryPeriod.week, now), DateTime(2026, 7, 6));
    expect(periodStart(HistoryPeriod.month, now), DateTime(2026, 7));
    expect(periodStart(HistoryPeriod.year, now), DateTime(2026));
  });

  test('an attack exactly at the boundary is included', () {
    final boundary = [at(DateTime(2026, 7, 6))]; // Monday 00:00
    expect(filterByPeriod(boundary, HistoryPeriod.week, now), hasLength(1));
  });
}
