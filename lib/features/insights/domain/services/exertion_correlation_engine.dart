import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../entities/exertion_correlation_result.dart';

/// Exertion correlation: what share of answered attacks involved
/// moderate-to-severe activity?
///
/// Self-report has no "rest day" baseline to compare against (unlike sleep or
/// steps), so this mirrors [CorrelationEngine]'s simple share-of-attacks
/// shape rather than [SleepCorrelationEngine]'s two-group comparison.
class ExertionCorrelationEngine {
  const ExertionCorrelationEngine({this.minAttacks = defaultMinAttacks})
    : assert(minAttacks > 0, 'minAttacks must be positive');

  /// Same floor as the pressure correlation: below this many answered
  /// attacks the share is statistically meaningless noise.
  static const int defaultMinAttacks = 15;

  final int minAttacks;

  ExertionCorrelationResult analyze(List<Attack> attacks) {
    final withExertion = attacks
        .where((a) => a.exertionLevel != null)
        .toList();

    if (withExertion.length < minAttacks) {
      return ExertionInsufficientData(
        attacksWithExertion: withExertion.length,
        requiredAttacks: minAttacks,
      );
    }

    final levels = withExertion.map((a) => a.exertionLevel!).toSet();
    if (levels.length == 1) {
      return ExertionNoVariation(attacksAnalyzed: withExertion.length);
    }

    int lightCount = 0;
    int moderateCount = 0;
    int severeCount = 0;

    for (final Attack attack in withExertion) {
      switch (attack.exertionLevel!) {
        case ExertionLevel.light:
          lightCount++;
        case ExertionLevel.moderate:
          moderateCount++;
        case ExertionLevel.severe:
          severeCount++;
      }
    }

    return ExertionInsight(
      attacksAnalyzed: withExertion.length,
      lightCount: lightCount,
      moderateCount: moderateCount,
      severeCount: severeCount,
    );
  }
}
