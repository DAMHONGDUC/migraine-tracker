part of 'correlation_body.dart';

class _Insight extends StatelessWidget {
  const _Insight({required this.result});

  final CorrelationInsight result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final threshold = result.dropThresholdHpa.toStringAsFixed(
      result.dropThresholdHpa % 1 == 0 ? 0 : 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counts while the sample is tiny: "2/3" claims only what it counted.
        if (result.isCountOnly)
          Text(
            '${result.attacksDuringPressureDrop}/${result.attacksAnalyzed}',
            style: AppTextStyle.displaySmall.w600,
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result.dropSharePercent),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) =>
                Text('${value.round()}%', style: AppTextStyle.displaySmall.w600),
          ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          l10n.insightsDropShareSentence(threshold),
          style: AppTextStyle.bodyMedium,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          result.isPreliminary
              ? l10n.insightsPreliminaryCaption(
                  result.attacksAnalyzed,
                  result.requiredAttacks,
                )
              : l10n.insightsAnalyzedCaption(result.attacksAnalyzed),
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
