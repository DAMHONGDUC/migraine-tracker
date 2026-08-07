import 'package:meta/meta.dart';

/// Outcome of the exertion analysis: how much of the pain follows exertion?
@immutable
sealed class ExertionCorrelationResult {
  const ExertionCorrelationResult({
    required this.attacksAnalyzed,
    required this.requiredAttacks,
  });

  /// Attacks the user actually answered the exertion question for.
  final int attacksAnalyzed;

  /// Where the figure stops moving with every new log. Not a gate — the
  /// analysis is returned below it too, flagged by [isPreliminary].
  final int requiredAttacks;

  /// The figure is real but still shifts a lot per attack, so say so beside it.
  bool get isPreliminary => attacksAnalyzed < requiredAttacks;
}

/// No attack carries an exertion answer yet, so there is nothing to count.
class ExertionInsufficientData extends ExertionCorrelationResult {
  const ExertionInsufficientData({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
  });
}

/// Every answered attack reports the same level, so it carries no signal.
class ExertionNoVariation extends ExertionCorrelationResult {
  const ExertionNoVariation({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
  });
}

/// The headline: how much of the pain follows moderate-to-severe exertion.
class ExertionInsight extends ExertionCorrelationResult {
  const ExertionInsight({
    required super.attacksAnalyzed,
    required super.requiredAttacks,
    required this.lightCount,
    required this.moderateCount,
    required this.severeCount,
    required this.minAttacksForShare,
  });

  final int lightCount;
  final int moderateCount;
  final int severeCount;

  /// Below this many attacks the card shows the counts, not the percentage.
  final int minAttacksForShare;

  int get moderateOrSevereCount => moderateCount + severeCount;

  /// Share of answered attacks reporting moderate or severe exertion, 0–100.
  double get moderateOrSeverePercent =>
      moderateOrSevereCount * 100 / attacksAnalyzed;

  /// A percentage off this few attacks is false precision — one attack is
  /// 0% or 100%. "2 of 3" is the same fact without the overclaim.
  bool get isCountOnly => attacksAnalyzed < minAttacksForShare;
}
