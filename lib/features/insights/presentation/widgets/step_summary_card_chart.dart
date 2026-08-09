part of 'step_summary_card.dart';

/// One bar per day, in steps.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<StepDay> days;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateFormat dayLabel = DateFormat.E(l10n.localeName);

    return SdChartFrameV2(
      title: l10n.stepsSummaryChartTitle,
      // Bars say nothing to VoiceOver — the average and the count do.
      semanticsLabel: l10n.a11yStepsSummaryChart(days.length),
      height: SdChartStyleV2.plotHeight,
      child: SdBarChartV2(
        bars: <SdBarV2>[
          for (final StepDay day in days)
            SdBarV2(
              value: day.count.toDouble(),
              label: dayLabel.format(day.date),
            ),
        ],
        color: AppColors.secondary,
        tooltip: (num value) => value.label(l10n),
      ),
    );
  }
}
