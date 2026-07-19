import '../../../attacks/domain/entities/attack.dart';

/// Local midnight of [instant] — the calendar's day key. Attacks are stored
/// in UTC, so a 23:00 UTC attack can belong to the next local day; grouping
/// must happen in local time or the calendar marks the wrong cell.
DateTime dayKey(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Groups attacks by their local calendar day, newest first within a day.
Map<DateTime, List<Attack>> attacksByDay(List<Attack> attacks) {
  final byDay = <DateTime, List<Attack>>{};
  for (final attack in attacks) {
    byDay.putIfAbsent(dayKey(attack.startedAt), () => []).add(attack);
  }
  for (final list in byDay.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return byDay;
}

/// The worst intensity logged on a day — drives the calendar cell's colour.
/// Returns null for days with no attacks.
int? peakIntensity(List<Attack> attacksOnDay) {
  if (attacksOnDay.isEmpty) return null;
  return attacksOnDay
      .map((a) => a.intensity)
      .reduce((a, b) => a > b ? a : b);
}
