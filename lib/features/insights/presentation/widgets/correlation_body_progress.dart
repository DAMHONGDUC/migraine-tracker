part of 'correlation_body.dart';

/// The "keep logging" road: shown while no attack carries weather at all.
class _Progress extends StatelessWidget {
  const _Progress({required this.result});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InsightProgressBody(
      icon: AppIconConstant.correlation,
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
