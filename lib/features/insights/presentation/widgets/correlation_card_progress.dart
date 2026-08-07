part of 'correlation_card.dart';

/// The "keep logging" road: shown to free users short of the minimum, and to
/// everyone while no attack carries weather at all.
class _Progress extends StatelessWidget {
  const _Progress({required this.result, required this.icon});

  final CorrelationResult result;

  /// A padlock only where premium is what stands in the way; waiting on data
  /// is not a locked door, and saying so to a paying user reads as a bug.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InsightProgressBody(
      icon: icon,
      message: l10n.insightsInsufficientData(
        result.requiredAttacks - result.attacksAnalyzed,
      ),
      progress: result.attacksAnalyzed / result.requiredAttacks,
      caption: l10n.insightsProgressCaption(
        result.attacksAnalyzed,
        result.requiredAttacks,
      ),
    );
  }
}
