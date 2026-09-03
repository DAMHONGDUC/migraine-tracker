import '../../../attacks/domain/entities/attack.dart';
import '../../../daily_log/domain/entities/daily_log.dart';
import '../../../daily_log/domain/enums/daily_factor.dart';
import '../entities/factor_association.dart';
import '../enums/map_factor.dart';

/// The trigger/protector map: for every factor, how often an attack followed the days that carried it against the days that did not.
///
/// This is the analysis the daily check-in exists for. Without a row on quiet
/// days there is no second group, and a "trigger" is then only a count of the
/// days that hurt — which is what v1.0 could say and why it never claimed a
/// trigger at all.
class FactorMapEngine {
  const FactorMapEngine({
    this.meaningfulEffect = defaultMeaningfulEffect,
    this.minDaysEitherSide = defaultMinDaysEitherSide,
    this.requiredDays = defaultRequiredDays,
    this.requiredAttacks = defaultRequiredAttacks,
  });

  /// A fifth apart, the same bar `TriggerVerdictEngine` uses — one idea of "meaningful" across the app.
  static const double defaultMeaningfulEffect = 0.2;

  /// Days needed on BOTH sides before a factor is graded. Four days against twenty-four is a coincidence with a percentage sign on it.
  static const int defaultMinDaysEitherSide = 5;

  /// Four weeks of answered days before the map draws at all — long enough to hold a whole cycle and most people's ordinary variation.
  static const int defaultRequiredDays = 28;

  /// The same baseline every other analysis in the app waits for.
  static const int defaultRequiredAttacks = 15;

  final double meaningfulEffect;
  final int minDaysEitherSide;
  final int requiredDays;
  final int requiredAttacks;

  FactorMap analyze({
    required List<DailyLog> logs,
    required List<Attack> attacks,
  }) {
    // Only answered days: a row Apple Health filled in with a step count says nothing about the day and would dilute both groups.
    final List<DailyLog> answered = logs
        .where((DailyLog log) => log.isAnswered)
        .toList(growable: false);
    final Set<DateTime> attackDays = <DateTime>{
      for (final Attack attack in attacks) _dayOf(attack.startedAt.toLocal()),
    };
    final List<FactorAssociation> associations = <FactorAssociation>[
      for (final MapFactor factor in MapFactor.values)
        _associate(factor, answered, attackDays),
    ]..sort(_widestGapFirst);

    return FactorMap(
      associations: associations,
      answeredDays: answered.length,
      requiredDays: requiredDays,
      attacks: attacks.length,
      requiredAttacks: requiredAttacks,
    );
  }

  /// Widest gap first, but every graded factor before every ungraded one: a factor with four days behind it can show an effect of 1.0, and that number is an artefact of the four days rather than a finding.
  int _widestGapFirst(FactorAssociation a, FactorAssociation b) {
    final bool aGraded = a.verdict != FactorVerdict.insufficient;
    final bool bGraded = b.verdict != FactorVerdict.insufficient;

    if (aGraded != bGraded) return aGraded ? -1 : 1;
    return b.effect.compareTo(a.effect);
  }

  FactorAssociation _associate(
    MapFactor factor,
    List<DailyLog> answered,
    Set<DateTime> attackDays,
  ) {
    int daysWith = 0;
    int daysWithout = 0;
    int attacksWith = 0;
    int attacksWithout = 0;

    for (final DailyLog log in answered) {
      final bool hurt = attackDays.contains(log.day);

      if (_carries(factor, log)) {
        daysWith++;
        if (hurt) attacksWith++;
      } else {
        daysWithout++;
        if (hurt) attacksWithout++;
      }
    }
    final double rateWith = daysWith == 0 ? 0 : attacksWith / daysWith;
    final double rateWithout = daysWithout == 0 ? 0 : attacksWithout / daysWithout;
    final double larger = rateWith > rateWithout ? rateWith : rateWithout;
    // Both groups quiet is a real answer — nothing happened either way — and dividing by zero would make it a NaN instead.
    final double effect = larger == 0 ? 0 : (rateWith - rateWithout).abs() / larger;

    return FactorAssociation(
      factor: factor,
      verdict: _verdict(
        daysWith: daysWith,
        daysWithout: daysWithout,
        rateWith: rateWith,
        rateWithout: rateWithout,
        effect: effect,
      ),
      daysWith: daysWith,
      daysWithout: daysWithout,
      attackRateWith: rateWith,
      attackRateWithout: rateWithout,
      effect: effect,
    );
  }

  FactorVerdict _verdict({
    required int daysWith,
    required int daysWithout,
    required double rateWith,
    required double rateWithout,
    required double effect,
  }) {
    if (daysWith < minDaysEitherSide || daysWithout < minDaysEitherSide) {
      return FactorVerdict.insufficient;
    }
    if (effect < meaningfulEffect) return FactorVerdict.notAssociated;
    return rateWith > rateWithout
        ? FactorVerdict.trigger
        : FactorVerdict.protector;
  }

  /// Whether the day carries the factor. The two derived ones read a rating; the rest read a tick.
  bool _carries(MapFactor factor, DailyLog log) {
    final DailyFactor? daily = factor.daily;

    if (daily != null) return log.factors.contains(daily);
    return switch (factor) {
      // Unanswered is not "good sleep": a rating nobody gave cannot put the day in either group, so it goes with the majority one and dilutes nothing.
      MapFactor.poorSleep => (log.sleepQuality ?? 5) <= 2,
      MapFactor.highStress => (log.stressLevel ?? 1) >= 4,
      _ => false,
    };
  }

  DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);
}
