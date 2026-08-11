part of 'sleep_card.dart';

/// The free half: last night, the range selector, and the nights behind it.
class _NightsSection extends ConsumerWidget {
  const _NightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // The switch lives on `/sleep`. The Apple Health sheet is only ever
    // raised on the screen that owns it, so this says where to go rather
    // than offering a Connect button here.
    if (!ref.watch(healthControllerProvider).sleep) {
      return Text(
        l10n.insightsSleepNotConnected,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    final HealthRange range = ref.watch(sleepRangeProvider);
    final List<SleepNight> nights =
        ref.watch(rangedSleepNightsProvider).value ?? const <SleepNight>[];
    final List<HealthBucket> buckets = HealthRangeBuckets.sleep(nights, range);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HealthRangeSelector(
          selected: range,
          onSelected: ref.read(sleepRangeProvider.notifier).set,
        ),
        SizedBox(height: SdSpacingConstant.h16),
        _Headline(nights: nights, range: range),
        SizedBox(height: SdSpacingConstant.h16),
        HealthRangeChart(
          buckets: buckets,
          range: range,
          color: AppColors.chartSeries,
          tooltip: (num value) =>
              Duration(minutes: (value * 60).round()).label(l10n),
          semanticsLabel: l10n.a11ySleepSummaryChart(buckets.length),
        ),
      ],
    );
  }
}

/// Last night on the Day range, the window's average on every other.
class _Headline extends StatelessWidget {
  const _Headline({required this.nights, required this.range});

  final List<SleepNight> nights;
  final HealthRange range;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isAverage = range != HealthRange.day;

    if (nights.isEmpty) {
      return Text(
        l10n.sleepSummaryEmpty,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    final double hours = isAverage
        ? nights.fold<double>(0, (double sum, SleepNight n) => sum + n.hours) /
              nights.length
        : nights.last.hours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isAverage ? l10n.sleepSummaryAverage : l10n.sleepSummaryLatest,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          Duration(minutes: (hours * 60).round()).label(l10n),
          style: AppTextStyle.headlineMedium.w600,
        ),
      ],
    );
  }
}
