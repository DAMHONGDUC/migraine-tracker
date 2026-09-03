import '../../../daily_log/domain/enums/daily_factor.dart';

/// Everything the trigger/protector map can weigh: what the check-in ticks, plus the two things it rates.
///
/// The two ratings become yes/no facts about a day so they sit on the same
/// footing as a tick — a map that mixed "how bad was it, 1–5" with "did it
/// happen" would be comparing two different questions on one screen.
enum MapFactor {
  skippedMeal,
  dehydration,
  caffeine,
  alcohol,
  screenTime,
  intenseExercise,
  travel,
  strongSmell,

  /// Sleep quality 1 or 2 out of 5.
  poorSleep,

  /// Stress 4 or 5 out of 5.
  highStress;

  /// The check-in tick this factor reads, or null for the two derived from a rating.
  DailyFactor? get daily => switch (this) {
    MapFactor.skippedMeal => DailyFactor.skippedMeal,
    MapFactor.dehydration => DailyFactor.dehydration,
    MapFactor.caffeine => DailyFactor.caffeine,
    MapFactor.alcohol => DailyFactor.alcohol,
    MapFactor.screenTime => DailyFactor.screenTime,
    MapFactor.intenseExercise => DailyFactor.intenseExercise,
    MapFactor.travel => DailyFactor.travel,
    MapFactor.strongSmell => DailyFactor.strongSmell,
    MapFactor.poorSleep || MapFactor.highStress => null,
  };
}
