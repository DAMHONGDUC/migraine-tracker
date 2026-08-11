part of 'activity_card.dart';

/// The free half: the step count, a D/W/M/6M selector, and the bars.
class _StepsSection extends ConsumerWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // The sheet is raised right here now (owner's call) — the user is
    // looking at the empty reading, so the fix belongs where they look.
    if (!ref.watch(healthControllerProvider).steps) {
      return HealthConnectPrompt(
        kind: HealthDataKind.steps,
        message: l10n.insightsStepsNotConnected,
      );
    }

    final HealthRange range = ref.watch(stepRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HealthRangeSelector(
          selected: range,
          onSelected: ref.read(stepRangeProvider.notifier).set,
        ),
        SizedBox(height: SdSpacingConstant.h16),
        // Today by hour, everything wider by day — a single daily total is
        // one bar, which is not a chart.
        if (range == HealthRange.day)
          const _StepHourChart()
        else
          _StepDayChart(range: range),
      ],
    );
  }
}

/// Today, one bar an hour.
class _StepHourChart extends ConsumerWidget {
  const _StepHourChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<StepHour> hours =
        ref.watch(stepHoursProvider).value ?? const <StepHour>[];
    final List<HealthBucket> buckets = <HealthBucket>[
      for (final StepHour hour in hours)
        HealthBucket(start: hour.hour, value: hour.count.toDouble()),
    ];

    return _StepTotal(
      total: hours.fold<int>(0, (int sum, StepHour h) => sum + h.count),
      chart: HealthRangeChart(
        buckets: buckets,
        range: HealthRange.day,
        color: AppColors.secondary,
        tooltip: (num value) => value.label(l10n),
        semanticsLabel: l10n.a11yStepsSummaryChart(buckets.length),
      ),
    );
  }
}

/// A week, a month or half a year, one bar a day (or a week at 6M).
class _StepDayChart extends ConsumerWidget {
  const _StepDayChart({required this.range});

  final HealthRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<StepDay> days =
        ref.watch(rangedStepDaysProvider).value ?? const <StepDay>[];
    final List<HealthBucket> buckets = HealthRangeBuckets.steps(days, range);

    return _StepTotal(
      // The window's own average, not the fixed 7-day one above it: the
      // figure has to describe the range the user picked.
      total: days.isEmpty
          ? 0
          : days.fold<int>(0, (int sum, StepDay d) => sum + d.count) ~/
                days.length,
      isAverage: true,
      chart: HealthRangeChart(
        buckets: buckets,
        range: range,
        color: AppColors.secondary,
        tooltip: (num value) => value.label(l10n),
        semanticsLabel: l10n.a11yStepsSummaryChart(buckets.length),
      ),
    );
  }
}

/// The headline figure over whichever chart was built.
class _StepTotal extends StatelessWidget {
  const _StepTotal({
    required this.total,
    required this.chart,
    this.isAverage = false,
  });

  final int total;
  final Widget chart;

  /// Whether [total] is a per-day average rather than a running total.
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isAverage ? l10n.stepsSummaryAverage : l10n.stepsSummaryLatest,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(total.label(l10n), style: AppTextStyle.headlineMedium.w600),
        SizedBox(height: SdSpacingConstant.h16),
        chart,
      ],
    );
  }
}
