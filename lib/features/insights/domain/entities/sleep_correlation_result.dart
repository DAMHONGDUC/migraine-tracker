import 'package:meta/meta.dart';

/// Outcome of the sleep analysis: do attacks follow short nights?
@immutable
sealed class SleepCorrelationResult {
  const SleepCorrelationResult();
}

/// Apple Health is not connected, so there is nothing to analyse. Produced by
/// the provider rather than the engine — the engine only ever sees data that
/// was actually read.
class SleepNotConnected extends SleepCorrelationResult {
  const SleepNotConnected();
}

/// Too few nights, or too few of one kind. Both groups need entries: an
/// average over "nights before an attack" means nothing without "every other
/// night" to compare it against.
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

/// The two averages are within noise of each other — sleep says nothing
/// about this user's attacks, which is a real answer, not a failure.
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
  });

  /// Mean sleep on nights followed by an attack.
  final Duration attackNightAverage;

  /// Mean sleep on every other night.
  final Duration restNightAverage;

  final int attackNights;
  final int restNights;

  int get nightsAnalyzed => attackNights + restNights;

  /// How much less the user slept before an attack. Negative means they
  /// slept *more* — an honest engine has to be able to say that.
  Duration get shortfall => restNightAverage - attackNightAverage;

  /// Whether the short nights are the ones attacks follow.
  bool get sleptLessBeforeAttacks => !shortfall.isNegative;
}
