part of 'history_screen.dart';

/// The stacked chart deck shown once the filtered period has attacks.
class _Charts extends StatelessWidget {
  const _Charts({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<Widget> charts = <Widget>[
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
        for (final (int index, Widget chart) in charts.indexed) ...[
          if (index > 0) SizedBox(height: SdSpacingConstant.h16),
          SdChartCardV2(child: chart),
        ],
      ],
    );
  }
}
