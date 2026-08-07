part of 'history_screen.dart';

/// The stacked chart deck shown once the filtered period has attacks: weekly
/// frequency, average-intensity trend, severity mix, pain-by-location and
/// time-of-day — each in its own [SdChartCardV2]. All read the same filtered
/// [attacks] and are computed once here (pure calculators).
///
/// Premium-only, except the dashboard's severity preview: a free user gets
/// the same five charts drawn from [SampleChartData], blurred under
/// [PremiumChartLock]. The branch is here, on the source list, so the free
/// tree never holds the user's own numbers at all.
class _Charts extends ConsumerWidget {
  const _Charts({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasPremium = ref.watch(hasPremiumProvider);
    final DateTime now = DateTime.now();
    final List<Attack> source = hasPremium
        ? attacks
        : SampleChartData.attacks(now: now);
    final List<Widget> cards = <Widget>[
      WeeklyFrequencyChart(
        buckets: const WeeklyBucketsCalculator().compute(source, now: now),
      ),
      IntensityTrendChart(
        points: const IntensityTrendCalculator().compute(source, now: now),
      ),
      SeverityBreakdownChart(
        counts: const SeverityBreakdownCalculator().compute(source),
      ),
      LocationBreakdownChart(
        counts: const LocationBreakdownCalculator().compute(source),
      ),
      TimeOfDayChart(counts: const TimeOfDayCalculator().compute(source)),
    ];

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: SdSpacingConstant.h16),
          SdChartCardV2(
            child: hasPremium ? cards[i] : PremiumChartLock(sample: cards[i]),
          ),
        ],
      ],
    );
  }
}
