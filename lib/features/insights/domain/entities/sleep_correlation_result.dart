import 'package:meta/meta.dart';

/// Outcome of the sleep analysis: do attacks follow short nights?
@immutable
sealed class SleepCorrelationResult {
  const SleepCorrelationResult();
}

/// Apple Health is not connected, so there is nothing to analyse.
class SleepNotConnected extends SleepCorrelationResult {
  const SleepNotConnected();
}

/// One of the two groups is empty, so no comparison exists at all.
class SleepInsufficientData extends SleepCorrelationResult {
  const SleepInsufficientData({
    required this.nightsWithSleep,
    required this.requiredNights,
    required this.attackNights,
    required this.restNights,
    required this.requiredPerGroup,
  });

  final int nightsWithSleep;
  final int requiredNights;

  /// Nights followed by an attack the next day.
  final int attackNights;

  /// Nights that were not.
  final int restNights;

  /// How many each of [attackNights] and [restNights] must reach.
  final int requiredPerGroup;
}

/// The two averages are within noise of each other — sleep says nothing about this user's attacks, which is a real answer, not a failure.
class SleepNoVariation extends SleepCorrelationResult {
  const SleepNoVariation({required this.nightsAnalyzed});

  final int nightsAnalyzed;
}

/// The headline: how much less (or more) the user slept before an attack.
class SleepInsight extends SleepCorrelationResult {
  const SleepInsight({
    required this.attackNightAverage,
    required this.restNightAverage,
    required this.attackNights,
    required this.restNights,
    required this.requiredNights,
    required this.requiredPerGroup,
  });

  /// Mean sleep on nights followed by an attack.
  final Duration attackNightAverage;

  /// Mean sleep on every other night.
  final Duration restNightAverage;

  final int attackNights;
  final int restNights;

  /// Where the comparison settles, and the minimum each side needs before the difference between them is worth stating as one number.
  final int requiredNights;
  final int requiredPerGroup;

  int get nightsAnalyzed => attackNights + restNights;

  /// The figure is real but still moves with every night, so say so beside it.
  bool get isPreliminary =>
      nightsAnalyzed < requiredNights ||
      attackNights < requiredPerGroup ||
      restNights < requiredPerGroup;

  /// One side is too thin for the difference to be worth a headline — show the two averages that were measured instead of the gap between them.
  bool get isCountOnly =>
      attackNights < requiredPerGroup || restNights < requiredPerGroup;

  /// How much less the user slept before an attack. Negative means they slept *more* — an honest engine has to be able to say that.
  Duration get shortfall => restNightAverage - attackNightAverage;

  /// Whether the short nights are the ones attacks follow.
  bool get sleptLessBeforeAttacks => !shortfall.isNegative;
}
