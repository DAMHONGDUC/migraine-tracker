import '../../../daily_log/domain/enums/daily_factor.dart';

/// Everything the trigger/protector map can weigh: what the check-in ticks, the two things it rates, and the two the weather answers for.
///
/// Every one becomes a yes/no fact about a day so they sit on the same footing
/// as a tick — a map that mixed "how bad was it, 1–5" with "did it happen"
/// would be comparing two different questions on one screen. The last two are
/// read from the daily weather rather than asked for: the app already records
/// them, and a user typing today's humidity would only ever be guessing.
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
  highStress,

  /// The day's humidity at or above `FactorMapEngine.humidPercent`.
  highHumidity,

  /// The day's temperature at least `FactorMapEngine.tempSwingCelsius` away from the day before.
  tempSwing;

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
    MapFactor.poorSleep ||
    MapFactor.highStress ||
    MapFactor.highHumidity ||
    MapFactor.tempSwing => null,
  };
}
