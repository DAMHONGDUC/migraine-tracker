part of 'correlation_card.dart';

class _Insight extends StatelessWidget {
  const _Insight({required this.result});

  final CorrelationInsight result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final threshold = result.dropThresholdHpa
        .toStringAsFixed(result.dropThresholdHpa % 1 == 0 ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: result.dropSharePercent),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            '${value.round()}%',
            style: AppTextStyle.displaySmall.w600,
          ),
        ),
        SizedBox(height: AppSpacingConstant.h4),
        Text(
          l10n.insightsDropShareSentence(threshold),
          style: AppTextStyle.bodyMedium,
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Text(
          l10n.insightsAnalyzedCaption(result.attacksAnalyzed),
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
