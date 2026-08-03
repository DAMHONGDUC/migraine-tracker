part of 'history_screen.dart';

/// The stacked chart deck shown once the filtered period has attacks: weekly
/// frequency, average-intensity trend, severity mix, pain-by-location and
/// time-of-day — each in its own [SdChartCardV2]. All read the same filtered
/// [attacks] and are computed once here (pure calculators).
class _Charts extends StatelessWidget {
  const _Charts({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cards = <Widget>[
      WeeklyFrequencyChart(
        buckets: const WeeklyBucketsCalculator().compute(attacks, now: now),
      ),
      IntensityTrendChart(
        points: const IntensityTrendCalculator().compute(attacks, now: now),
      ),
      SeverityBreakdownChart(
        counts: const SeverityBreakdownCalculator().compute(attacks),
      ),
      LocationBreakdownChart(
        counts: const LocationBreakdownCalculator().compute(attacks),
      ),
      TimeOfDayChart(counts: const TimeOfDayCalculator().compute(attacks)),
    ];

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: SdSpacingConstant.h16),
          SdChartCardV2(child: cards[i]),
        ],
      ],
    );
  }
}
