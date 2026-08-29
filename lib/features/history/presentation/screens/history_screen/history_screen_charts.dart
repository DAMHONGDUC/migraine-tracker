part of 'history_screen.dart';

/// The stacked chart deck shown once the filtered period has attacks.
class _Charts extends ConsumerWidget {
  const _Charts({required this.attacks});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasPremium = ref.watch(hasPremiumProvider);
    final DateTime now = DateTime.now();
    final List<Attack> gated = hasPremium
        ? attacks
        : SampleChartData.attacks(now: now);
    final List<({Widget chart, bool locked})> cards =
        <({Widget chart, bool locked})>[
          (
            chart: WeeklyFrequencyChart(
              buckets: const WeeklyBucketsCalculator().compute(gated, now: now),
            ),
            locked: !hasPremium,
          ),
          (
            chart: IntensityTrendChart(
              points: const IntensityTrendCalculator().compute(gated, now: now),
            ),
            locked: !hasPremium,
          ),
          // Free at every tier: the same donut the dashboard shows, so locking it here would take back what the user already has.
          (
            chart: SeverityBreakdownChart(
              counts: const SeverityBreakdownCalculator().compute(attacks),
            ),
            locked: false,
          ),
          (
            chart: LocationBreakdownChart(
              counts: const LocationBreakdownCalculator().compute(gated),
            ),
            locked: !hasPremium,
          ),
          (
            chart: TimeOfDayChart(
              counts: const TimeOfDayCalculator().compute(gated),
            ),
            locked: !hasPremium,
          ),
        ];

    return Column(
      children: [
        for (final (int index, ({Widget chart, bool locked}) card)
            in cards.indexed) ...[
          if (index > 0) SizedBox(height: SdSpacingConstant.h16),
          SdChartCardV2(
            child: card.locked
                ? PremiumChartLock(sample: card.chart)
                : card.chart,
          ),
        ],
      ],
    );
  }
}
