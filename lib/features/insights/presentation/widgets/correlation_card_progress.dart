part of 'correlation_card.dart';

/// The "keep logging" road: shown to free users short of the minimum, and to
/// everyone while no attack carries weather at all.
class _Progress extends StatelessWidget {
  const _Progress({required this.result});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InsightProgressBody(
      icon: Icons.lock_outline,
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
