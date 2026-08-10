import 'package:meta/meta.dart';

/// Outcome of a correlation analysis over the user's attack history.
@immutable
sealed class CorrelationResult {
  const CorrelationResult({
    required this.attacksAnalyzed,
    required this.requiredAttacks,
  });

  /// Attacks that had a weather snapshot attached (only these count).
  final int attacksAnalyzed;

  /// Where the figure stops moving with every new log. Not a gate — the
  /// analysis is returned below it too, flagged by [isPreliminary].
  final int requiredAttacks;

  /// The figure is real but still shifts a lot per attack, so say so beside it.
  bool get isPreliminary => attacksAnalyzed < requiredAttacks;
}

/// No attack carries a weather snapshot yet, so there is nothing to count.
class CorrelationInsufficientData extends CorrelationResult {
  const CorrelationInsufficientData({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
  });
}

/// All snapshots show (nearly) identical pressure behaviour, so the drop
/// share carries no signal — e.g. a user in a climate with flat pressure.
class CorrelationNoVariation extends CorrelationResult {
  const CorrelationNoVariation({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
  });
}

/// The comparison that turns the share into a claim about risk.
///
/// Without it the card can only say what share of the user's attacks fell
/// during drops — which is high for anyone living somewhere stormy, whether
/// or not pressure has anything to do with their migraines. This says how
/// often a drop day ended in an attack against how often a calm day did.
@immutable
class PressureBaseline {
  const PressureBaseline({
    required this.dropDays,
    required this.dropDaysWithAttack,
    required this.calmDays,
    required this.calmDaysWithAttack,
    required this.minDaysPerSide,
  });

  final int dropDays;
  final int dropDaysWithAttack;
  final int calmDays;
  final int calmDaysWithAttack;

  /// How many days each side needs before the comparison is worth stating.
  final int minDaysPerSide;

  /// Share of drop days that ended in an attack, 0–100.
  double get dropDayAttackPercent => dropDaysWithAttack * 100 / dropDays;

  /// The same for days pressure did not fall.
  double get calmDayAttackPercent => calmDaysWithAttack * 100 / calmDays;

  /// How many times more likely an attack is on a drop day. Null when no calm
  /// day ended in an attack — dividing by zero would print "infinitely more
  /// likely", which is a claim four quiet days cannot support.
  double? get timesMoreLikely => calmDaysWithAttack == 0
      ? null
      : dropDayAttackPercent / calmDayAttackPercent;

  /// Both sides need days in them: one drop day that happened to end in an
  /// attack is 100%, and reads as a finding.
  bool get isReliable =>
      dropDays >= minDaysPerSide && calmDays >= minDaysPerSide;
}

/// The headline insight: "X% of your attacks occurred during rapid
/// pressure drops."
class CorrelationInsight extends CorrelationResult {
  const CorrelationInsight({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
    required this.attacksDuringPressureDrop,
    required this.dropThresholdHpa,
    required this.minAttacksForShare,
    this.baseline,
  });

  /// Null until enough days have been recorded — the app only started
  /// keeping days without attacks recently, so an existing user's history
  /// has none and the card falls back to the share alone.
  final PressureBaseline? baseline;

  final int attacksDuringPressureDrop;

  /// Threshold used to classify a snapshot as a "rapid drop" (hPa per 24h).
  final double dropThresholdHpa;

  /// Below this many attacks the card shows the counts, not the percentage.
  final int minAttacksForShare;

  /// Share of attacks during rapid drops, 0–100.
  double get dropSharePercent =>
      attacksDuringPressureDrop * 100 / attacksAnalyzed;

  /// A percentage off this few attacks is false precision — one attack is
  /// 0% or 100%. "2 of 3" is the same fact without the overclaim.
  bool get isCountOnly => attacksAnalyzed < minAttacksForShare;
}
