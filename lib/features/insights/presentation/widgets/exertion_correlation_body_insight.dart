part of 'exertion_correlation_body.dart';

class _Insight extends StatelessWidget {
  const _Insight({required this.result});

  final ExertionInsight result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counts while the sample is tiny: "2/3" claims only what it counted.
        if (result.isCountOnly)
          Text(
            '${result.moderateOrSevereCount}/${result.attacksAnalyzed}',
            style: AppTextStyle.displaySmall.w600,
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result.moderateOrSeverePercent),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Text(
              '${value.round()}%',
              style: AppTextStyle.displaySmall.w600,
            ),
          ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(l10n.insightsExertionSentence, style: AppTextStyle.bodyMedium),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          l10n.insightsExertionAnalyzedCaption(result.attacksAnalyzed),
          style: AppTextStyle.bodySmall.secondary,
        ),
        if (result.isPreliminary) const InsightSettlingNote(),
      ],
    );
  }
}
