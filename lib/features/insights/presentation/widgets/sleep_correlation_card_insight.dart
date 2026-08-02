part of 'sleep_correlation_card.dart';

/// The headline: the gap between the two averages, then both averages so the
/// number is never a claim the user has to take on trust.
class _SleepInsightBody extends StatelessWidget {
  const _SleepInsightBody({required this.result});

  final SleepInsight result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          result.shortfall.label(l10n),
          style: AppTextStyle.displaySmall.w600,
        ),
        SizedBox(height: AppSpacingConstant.h4),
        Text(
          result.sleptLessBeforeAttacks
              ? l10n.insightsSleepLessSentence
              : l10n.insightsSleepMoreSentence,
          style: AppTextStyle.bodyMedium,
        ),
        SizedBox(height: AppSpacingConstant.h16),
        _AverageRow(
          label: l10n.insightsSleepAttackNights,
          value: result.attackNightAverage.label(l10n),
        ),
        SizedBox(height: AppSpacingConstant.h8),
        _AverageRow(
          label: l10n.insightsSleepRestNights,
          value: result.restNightAverage.label(l10n),
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Text(
          l10n.insightsSleepAnalyzedCaption(
            result.attackNights,
            result.restNights,
          ),
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}

/// Label left, average right. The label takes the slack so a long
/// translation wraps instead of pushing the number off the card.
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
        SizedBox(width: AppSpacingConstant.w12),
        Text(value, style: AppTextStyle.bodyMedium.w600),
      ],
    );
  }
}
