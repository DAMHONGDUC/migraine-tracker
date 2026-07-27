import '../entities/medication.dart';

/// Orders the log flow's medication picker by what the user actually reaches
/// for. Pure Dart, no state — unit-tested independently.
class MedicationRanking {
  const MedicationRanking();

  /// Alphabetical order is wrong at the moment of use: mid-attack the med you
  /// took last time should be the first thing under your thumb, not the one
  /// whose name starts with "A". Recency is derived from attack history rather
  /// than a denormalized `lastUsedAt` column, so there is nothing to keep in
  /// sync and existing histories rank correctly with no migration.
  ///
  /// [recentNamesNewestFirst] is every logged attack's medication name, newest
  /// first; nulls ("no medication") and names with no matching [Medication]
  /// are ignored. Medications never taken keep their incoming order — the
  /// repository already sorts alphabetically — and follow the ranked ones.
  static List<Medication> byRecentUse(
    List<Medication> medications,
    Iterable<String?> recentNamesNewestFirst,
  ) {
    if (medications.length < 2) return medications;

    // First sighting of a name is its most recent use, so later duplicates
    // never overwrite a better rank.
    final rankByName = <String, int>{};
    int rank = 0;
    for (final name in recentNamesNewestFirst) {
      if (name == null) continue;
      rankByName.putIfAbsent(name, () => rank++);
    }
    if (rankByName.isEmpty) return medications;

    // Stable sort keeps the alphabetical tail intact: List.sort is not
    // stable, so unranked meds are partitioned out instead of compared.
    final ranked = <Medication>[];
    final unranked = <Medication>[];
    for (final medication in medications) {
      (rankByName.containsKey(medication.name) ? ranked : unranked).add(
        medication,
      );
    }
    ranked.sort((a, b) => rankByName[a.name]!.compareTo(rankByName[b.name]!));
    return [...ranked, ...unranked];
  }
}
