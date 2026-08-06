import 'package:meta/meta.dart';

/// Outcome of the step analysis: do attacks follow low-activity days?
@immutable
sealed class StepCorrelationResult {
  const StepCorrelationResult();
}

/// Apple Health is not connected, so there is nothing to analyse. Produced by
/// the provider rather than the engine — the engine only ever sees data that
/// was actually read.
class StepNotConnected extends StepCorrelationResult {
  const StepNotConnected();
}

/// Too few days, or too few of one kind. Both groups need entries: an
/// average over "attack days" means nothing without "every other day" to
/// compare it against.
class StepInsufficientData extends StepCorrelationResult {
  const StepInsufficientData({
    required this.daysWithSteps,
    required this.requiredDays,
    required this.attackDays,
    required this.restDays,
    required this.requiredPerGroup,
  });

  final int daysWithSteps;
  final int requiredDays;

  /// Days an attack started on.
  final int attackDays;

  /// Days that were not.
  final int restDays;

  /// How many each of [attackDays] and [restDays] must reach.
  final int requiredPerGroup;
}

/// The two averages are within noise of each other — steps say nothing about
/// this user's attacks, which is a real answer, not a failure.
class StepNoVariation extends StepCorrelationResult {
  const StepNoVariation({required this.daysAnalyzed});

  final int daysAnalyzed;
}

/// The headline: how many fewer (or more) steps the user took on attack days.
class StepInsight extends StepCorrelationResult {
  const StepInsight({
    required this.attackDayAverage,
    required this.restDayAverage,
    required this.attackDays,
    required this.restDays,
  });

  /// Mean steps on days an attack started.
  final double attackDayAverage;

  /// Mean steps on every other day.
  final double restDayAverage;

  final int attackDays;
  final int restDays;

  int get daysAnalyzed => attackDays + restDays;

  /// How many fewer steps the user took on an attack day. Negative means
  /// they moved *more* — an honest engine has to be able to say that.
  double get shortfall => restDayAverage - attackDayAverage;

  /// Whether attacks follow the days the user moved less.
  bool get movedLessOnAttackDays => shortfall > 0;
}
