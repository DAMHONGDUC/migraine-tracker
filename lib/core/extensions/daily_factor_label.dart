import '../../features/daily_log/domain/enums/daily_factor.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared user-facing labels for [DailyFactor]; the check-in picks them and the insights read them back, so neither imports the other's presentation layer.
extension DailyFactorLabel on DailyFactor {
  String label(AppLocalizations l10n) => switch (this) {
    DailyFactor.skippedMeal => l10n.dailyLogFactorSkippedMeal,
    DailyFactor.dehydration => l10n.dailyLogFactorDehydration,
    DailyFactor.caffeine => l10n.dailyLogFactorCaffeine,
    DailyFactor.alcohol => l10n.dailyLogFactorAlcohol,
    DailyFactor.screenTime => l10n.dailyLogFactorScreenTime,
    DailyFactor.intenseExercise => l10n.dailyLogFactorIntenseExercise,
    DailyFactor.travel => l10n.dailyLogFactorTravel,
    DailyFactor.strongSmell => l10n.dailyLogFactorStrongSmell,
  };
}
