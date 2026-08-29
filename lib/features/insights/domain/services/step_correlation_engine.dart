import '../../../attacks/domain/entities/attack.dart';
import '../../../health/domain/entities/step_day.dart';
import '../entities/step_correlation_result.dart';

/// Step correlation: did the user move less on the days their attacks started?
class StepCorrelationEngine {
  const StepCorrelationEngine({
    this.minDays = defaultMinDays,
    this.minDaysPerGroup = defaultMinDaysPerGroup,
    this.variationEpsilonSteps = defaultVariationEpsilonSteps,
  }) : assert(minDays > 0, 'minDays must be positive'),
       assert(minDaysPerGroup > 0, 'minDaysPerGroup must be positive');

  /// Same floor as the sleep correlation: below this many days the comparison is noise.
  static const int defaultMinDays = 15;

  /// And each side of the comparison needs its own minimum — 14 quiet days and one attack day is one anecdote, not an average.
  static const int defaultMinDaysPerGroup = 3;

  /// Averages closer than this are the same activity as far as a person is concerned.
  static const double defaultVariationEpsilonSteps = 1000;

  /// How far back to read steps for the analysis.
  static const int defaultLookbackDays = 180;

  final int minDays;
  final int minDaysPerGroup;
  final double variationEpsilonSteps;

  StepCorrelationResult analyze({
    required List<Attack> attacks,
    required List<StepDay> days,
  }) {
    final Set<DateTime> attackDates = <DateTime>{
      for (final Attack attack in attacks) _localDate(attack.startedAt),
    };
    final List<StepDay> attackDays = <StepDay>[];
    final List<StepDay> restDays = <StepDay>[];

    for (final StepDay day in days) {
      final DateTime date = _dateOnly(day.date);

      (attackDates.contains(date) ? attackDays : restDays).add(day);
    }

    // An empty side is the one thing no result can be built from: there is no comparison, not merely a thin one.
    if (attackDays.isEmpty || restDays.isEmpty) {
      return StepInsufficientData(
        daysWithSteps: days.length,
        requiredDays: minDays,
        attackDays: attackDays.length,
        restDays: restDays.length,
        requiredPerGroup: minDaysPerGroup,
      );
    }

    final double attackAverage = _average(attackDays);
    final double restAverage = _average(restDays);
    final bool settled =
        days.length >= minDays &&
        attackDays.length >= minDaysPerGroup &&
        restDays.length >= minDaysPerGroup;

    // "The same activity" is only a verdict at a real sample; below it the card shows the two averages, which need no spread to be true.
    if (settled && (restAverage - attackAverage).abs() < variationEpsilonSteps) {
      return StepNoVariation(daysAnalyzed: days.length);
    }

    return StepInsight(
      attackDayAverage: attackAverage,
      restDayAverage: restAverage,
      attackDays: attackDays.length,
      restDays: restDays.length,
      requiredDays: minDays,
      requiredPerGroup: minDaysPerGroup,
    );
  }

  /// Mean of [days]; the caller has already ruled out an empty list.
  double _average(List<StepDay> days) {
    int total = 0;

    for (final StepDay day in days) {
      total += day.count;
    }

    return total / days.length;
  }

  DateTime _localDate(DateTime instant) => _dateOnly(instant.toLocal());

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
