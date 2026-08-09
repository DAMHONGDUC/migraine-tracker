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
        // The share alone says nothing about risk — someone in a stormy
        // climate scores high whatever causes their migraines. This is the
        // comparison against days that had no attack.
        if (result.baseline case final PressureBaseline baseline) ...<Widget>[
          Text(
            l10n.insightsBaselineSentence(
              baseline.dropDayAttackPercent.round(),
              baseline.calmDayAttackPercent.round(),
            ),
            style: AppTextStyle.bodyMedium,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            l10n.insightsBaselineDays(baseline.dropDays, baseline.calmDays),
            style: AppTextStyle.bodySmall.secondary,
          ),
          SizedBox(height: SdSpacingConstant.h4),
        ],
        Text(
          l10n.insightsAnalyzedCaption(result.attacksAnalyzed),
          style: AppTextStyle.bodySmall.secondary,
        ),
        if (result.isPreliminary) const InsightSettlingNote(),
      ],
    );
  }
}
