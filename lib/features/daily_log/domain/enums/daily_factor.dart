/// The things a day can carry that an attack might follow.
///
/// A fixed list on purpose: the trigger/protector analysis compares a factor's
/// attack rate against its own absence, so a factor invented in week three has
/// too few days behind it to grade and no two users' maps would mean the same
/// thing. Adding one is a release decision — see `docs/rules/DECISIONS.md`.
enum DailyFactor {
  skippedMeal,
  dehydration,
  caffeine,
  alcohol,
  screenTime,
  intenseExercise,
  travel,
  strongSmell,
  // Added 2026-09-14 with the attack's trigger chips: an attack names these
  // often and the map had no day-level counterpart to grade them against.
  // Each starts its own 28-day clock (`FactorMapEngine.defaultRequiredDays`).
  brightLight,
  loudNoise,
  neckTension,
  missedMedication;

  /// A stored trigger string back to the factor it names, or null for a word the user typed themselves.
  ///
  /// An attack's triggers and a day's factors share this vocabulary, which is
  /// what lets `FactorMapEngine` weigh a trigger against the days it did not
  /// hurt — see `lib/features/daily_log/CLAUDE.md`.
  static DailyFactor? tryParse(String value) {
    for (final DailyFactor factor in DailyFactor.values) {
      if (factor.name == value) return factor;
    }

    return null;
  }
}
