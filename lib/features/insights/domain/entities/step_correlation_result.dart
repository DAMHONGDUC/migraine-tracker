import 'package:meta/meta.dart';

/// Outcome of the step analysis: do attacks follow low-activity days?
@immutable
sealed class StepCorrelationResult {
  const StepCorrelationResult();
}

/// Apple Health is not connected, so there is nothing to analyse.
class StepNotConnected extends StepCorrelationResult {
  const StepNotConnected();
}

/// One of the two groups is empty, so no comparison exists at all.
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

/// The two averages are within noise of each other — steps say nothing about this user's attacks, which is a real answer, not a failure.
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
    required this.requiredDays,
    required this.requiredPerGroup,
  });

  /// Mean steps on days an attack started.
  final double attackDayAverage;

  /// Mean steps on every other day.
  final double restDayAverage;

  final int attackDays;
  final int restDays;

  /// Where the comparison settles, and the minimum each side needs before the difference between them is worth stating as one number.
  final int requiredDays;
  final int requiredPerGroup;

  int get daysAnalyzed => attackDays + restDays;

  /// The figure is real but still moves with every day, so say so beside it.
  bool get isPreliminary =>
      daysAnalyzed < requiredDays ||
      attackDays < requiredPerGroup ||
      restDays < requiredPerGroup;

  /// One side is too thin for the difference to be worth a headline — show the two averages that were measured instead of the gap between them.
  bool get isCountOnly =>
      attackDays < requiredPerGroup || restDays < requiredPerGroup;

  /// How many fewer steps the user took on an attack day. Negative means they moved *more* — an honest engine has to be able to say that.
  double get shortfall => restDayAverage - attackDayAverage;

  /// Whether attacks follow the days the user moved less.
  bool get movedLessOnAttackDays => shortfall > 0;
}
