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
}
