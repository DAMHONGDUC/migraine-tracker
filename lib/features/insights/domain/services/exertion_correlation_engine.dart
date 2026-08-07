import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../entities/exertion_correlation_result.dart';

/// Exertion correlation: what share of answered attacks involved
/// moderate-to-severe activity?
///
/// Self-report has no "rest day" baseline to compare against (unlike sleep or
/// steps), so this mirrors [CorrelationEngine]'s simple share-of-attacks
/// shape rather than [SleepCorrelationEngine]'s two-group comparison — and,
/// like it, grades the answer rather than withholding it.
class ExertionCorrelationEngine {
  const ExertionCorrelationEngine({
    this.minAttacks = defaultMinAttacks,
    this.minAttacksForShare = defaultMinAttacksForShare,
  }) : assert(minAttacks > 0, 'minAttacks must be positive'),
       assert(minAttacksForShare > 0, 'minAttacksForShare must be positive');

  /// Same floor as the pressure correlation, for the same reason: the normal
  /// approximation wants ~5 attacks either side of the split.
  static const int defaultMinAttacks = 15;

  /// Below this the result asks for counts instead of a percentage.
  static const int defaultMinAttacksForShare = 5;

  final int minAttacks;
  final int minAttacksForShare;

  ExertionCorrelationResult analyze(List<Attack> attacks) {
    final List<Attack> withExertion = attacks
        .where((a) => a.exertionLevel != null)
        .toList();

    if (withExertion.isEmpty) {
      return ExertionInsufficientData(
        attacksAnalyzed: 0,
        requiredAttacks: minAttacks,
      );
    }

    final Set<ExertionLevel> levels = withExertion
        .map((a) => a.exertionLevel!)
        .toSet();

    // One level everywhere only means something with several to compare;
    // below that the card shows counts, which need no spread to be true.
    if (withExertion.length >= minAttacksForShare && levels.length == 1) {
      return ExertionNoVariation(
        attacksAnalyzed: withExertion.length,
        requiredAttacks: minAttacks,
      );
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
      requiredAttacks: minAttacks,
      lightCount: lightCount,
      moderateCount: moderateCount,
      severeCount: severeCount,
      minAttacksForShare: minAttacksForShare,
    );
  }
}
