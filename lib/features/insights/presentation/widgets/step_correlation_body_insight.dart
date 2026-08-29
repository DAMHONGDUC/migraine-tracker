part of 'step_correlation_body.dart';

/// The headline: the gap between the two averages, then both averages so the number is never a claim the user has to take on trust.
class _StepInsightBody extends StatelessWidget {
  const _StepInsightBody({required this.result});

  final StepInsight result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // One thin side makes the gap between the averages a claim neither supports — show what was measured and skip the headline.
        if (!result.isCountOnly) ...<Widget>[
          Text(
            result.shortfall.abs().label(l10n),
            style: AppTextStyle.displaySmall.w600,
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            result.movedLessOnAttackDays
                ? l10n.insightsStepsLessSentence
                : l10n.insightsStepsMoreSentence,
            style: AppTextStyle.bodyMedium,
          ),
          SizedBox(height: SdSpacingConstant.h16),
        ],
        _AverageRow(
          label: l10n.insightsStepsAttackDays,
          value: result.attackDayAverage.label(l10n),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        _AverageRow(
          label: l10n.insightsStepsRestDays,
          value: result.restDayAverage.label(l10n),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          l10n.insightsStepsAnalyzedCaption(result.attackDays, result.restDays),
          style: AppTextStyle.bodySmall.secondary,
        ),
        if (result.isPreliminary) const InsightSettlingNote(),
      ],
    );
  }
}

/// Label left, average right. The label takes the slack so a long translation wraps instead of pushing the number off the card.
class _AverageRow extends StatelessWidget {
  const _AverageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(label, style: AppTextStyle.bodyMedium.secondary),
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Text(value, style: AppTextStyle.bodyMedium.w600),
      ],
    );
  }
}
