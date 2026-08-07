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

/// The headline insight: "X% of your attacks occurred during rapid
/// pressure drops."
class CorrelationInsight extends CorrelationResult {
  const CorrelationInsight({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
    required this.attacksDuringPressureDrop,
    required this.dropThresholdHpa,
    required this.minAttacksForShare,
  });

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
