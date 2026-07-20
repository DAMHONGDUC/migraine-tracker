import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/domain/services/attacks_by_day.dart';

Attack at(String id, DateTime local, {int intensity = 5}) => Attack(
  id: id,
  startedAt: local.toUtc(),
  intensity: intensity,
  location: HeadLocation.left,
);

void main() {
  const grouper = AttacksByDayGrouper();

  test('groups attacks into their local calendar day', () {
    final byDay = grouper.groupByDay([
      at('a', DateTime(2026, 7, 8, 9)),
      at('b', DateTime(2026, 7, 8, 21)),
      at('c', DateTime(2026, 7, 9, 1)),
    ]);

    expect(byDay.keys.toSet(), {DateTime(2026, 7, 8), DateTime(2026, 7, 9)});
    expect(byDay[DateTime(2026, 7, 8)]!.map((a) => a.id), ['b', 'a']);
  });

  test('day keys are midnight-normalized', () {
    expect(
      grouper.dayKey(DateTime(2026, 7, 8, 23, 59).toUtc()),
      DateTime(2026, 7, 8),
    );
    expect(grouper.dayKey(DateTime(2026, 7, 8).toUtc()), DateTime(2026, 7, 8));
  });

  test('an attack near midnight lands on its LOCAL day, not the UTC one', () {
    // Stored in UTC; grouped by local wall time.
    final local = DateTime(2026, 7, 8, 23, 30);
    final byDay = grouper.groupByDay([at('late', local)]);
    expect(byDay.keys.single, DateTime(2026, 7, 8));
  });

  test('peakIntensity returns the worst attack of the day', () {
    final day = [
      at('a', DateTime(2026, 7, 8, 9), intensity: 4),
      at('b', DateTime(2026, 7, 8, 20), intensity: 9),
      at('c', DateTime(2026, 7, 8, 22), intensity: 6),
    ];
    expect(grouper.peakIntensity(day), 9);
  });

  test('peakIntensity is null for an empty day', () {
    expect(grouper.peakIntensity([]), isNull);
  });

  test('empty input yields no days', () {
    expect(grouper.groupByDay([]), isEmpty);
  });
}
