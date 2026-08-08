part of 'sleep_summary_card.dart';

/// One bar per night, in hours.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.nights});

  final List<SleepNight> nights;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateFormat dayLabel = DateFormat.E(l10n.localeName);

    return SdChartFrameV2(
      title: l10n.sleepSummaryChartTitle,
      // Bars say nothing to VoiceOver — the average and the count do.
      semanticsLabel: l10n.a11ySleepSummaryChart(nights.length),
      height: SdChartStyleV2.plotHeight,
      child: SdBarChartV2(
        bars: <SdBarV2>[
          for (final SleepNight night in nights)
            SdBarV2(value: night.hours, label: dayLabel.format(night.date)),
        ],
        color: AppColors.chartSeries,
        tooltip: (num value) =>
            Duration(minutes: (value * 60).round()).label(l10n),
      ),
    );
  }
}
