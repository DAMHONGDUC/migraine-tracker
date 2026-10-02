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
            builder: (context, value, child) => Text(
              '${value.round()}%',
              style: AppTextStyle.displaySmall.w600,
            ),
          ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          l10n.insightsDropShareSentence(threshold),
          style: AppTextStyle.bodyMedium,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        // The share alone says nothing about risk — someone in a stormy climate scores high whatever causes their migraines.
        if (result.baseline case final PressureBaseline baseline) ...<Widget>[
          Text(
            l10n.insightsBaselineSentence(
              baseline.dropDayAttackPercent.round(),
              baseline.calmDayAttackPercent.round(),
            ),
            style: AppTextStyle.bodyMedium,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          // The sentence's two numbers drawn side by side (2026-09-30 redesign): the comparison is the whole finding, and two bars on one track make the gap visible before a word is read.
          _ComparisonBar(
            label: l10n.insightsBaselineDropDays,
            percent: baseline.dropDayAttackPercent,
            color: AppColors.chartSeries,
            emphasised: true,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          _ComparisonBar(
            label: l10n.insightsBaselineOtherDays,
            percent: baseline.calmDayAttackPercent,
            color: AppColors.textSecondary,
            emphasised: false,
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

/// One side of the drop-day comparison: its name and share on one line, the share as a bar under it.
///
/// Not `SdProgressRowV2`: that row gives its label a fixed 84pt column, and
/// "Days pressure fell" is longer than that in every shipped locale. Here the
/// label has the card's full width, so it never ellipses.
class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.percent,
    required this.color,
    required this.emphasised,
  });

  final String label;

  /// 0–100.
  final double percent;
  final Color color;

  /// The drop-day side reads first; the baseline it is measured against stays muted.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = emphasised
        ? AppTextStyle.bodyMedium
        : AppTextStyle.bodyMedium.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: style)),
            SizedBox(width: SdSpacingConstant.w8),
            Text('${percent.round()}%', style: style.w600),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h6),
        ClipRRect(
          borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
          child: Stack(
            children: [
              Container(
                height: SdSpacingConstant.h8,
                color: context.sdTheme.chartGrid,
              ),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0, 1),
                child: Container(height: SdSpacingConstant.h8, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
