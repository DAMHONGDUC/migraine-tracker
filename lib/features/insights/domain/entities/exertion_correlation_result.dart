import 'package:meta/meta.dart';

/// Outcome of the exertion analysis: how much of the pain follows exertion?
@immutable
sealed class ExertionCorrelationResult {
  const ExertionCorrelationResult();
}

/// Not enough attacks with an exertion answer to say anything meaningful.
class ExertionInsufficientData extends ExertionCorrelationResult {
  const ExertionInsufficientData({
    required this.attacksWithExertion,
    required this.requiredAttacks,
  });

  /// Attacks the user actually answered the exertion question for.
  final int attacksWithExertion;
  final int requiredAttacks;
}

/// Every answered attack reports the same level, so it carries no signal.
class ExertionNoVariation extends ExertionCorrelationResult {
  const ExertionNoVariation({required this.attacksAnalyzed});

  final int attacksAnalyzed;
}

/// The headline: how much of the pain follows moderate-to-severe exertion.
class ExertionInsight extends ExertionCorrelationResult {
  const ExertionInsight({
    required this.attacksAnalyzed,
    required this.lightCount,
    required this.moderateCount,
    required this.severeCount,
  });

  final int attacksAnalyzed;
  final int lightCount;
  final int moderateCount;
  final int severeCount;

  /// Share of answered attacks reporting moderate or severe exertion, 0–100.
  double get moderateOrSeverePercent =>
      (moderateCount + severeCount) * 100 / attacksAnalyzed;
}
