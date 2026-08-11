part of 'insights_screen.dart';

/// The selected tab's card, scrollable and refreshable.
///
/// **Each tab waits only on what it draws.** The screen used to hold every
/// card behind one `switch` on both correlation providers, so the weather —
/// which needs neither — was blank until the engines had run. Here the
/// weather tab renders immediately and only the two analysis tabs wait.
class _TabBody extends ConsumerWidget {
  const _TabBody({required this.tab});

  final InsightsTab tab;

  /// Everything a pull-to-refresh should re-fetch, whichever tab is up: the
  /// gesture belongs to the screen, so it must not refresh only part of it.
  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(attacksStreamProvider)
      ..invalidate(pressureForecastProvider)
      ..invalidate(weatherReportProvider)
      ..invalidate(sleepCorrelationProvider)
      ..invalidate(rangedStepDaysProvider)
      ..invalidate(rangedSleepNightsProvider)
      ..invalidate(stepHoursProvider)
      ..invalidate(stepCorrelationProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdRefreshIndicatorV2(
      onRefresh: () => SdRefreshIndicatorV2.run(() => _refresh(ref)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // The tab strip already took the app bar's gap, so this adds only
        // the strip's own separation and the bottom clearance.
        padding: EdgeInsets.fromLTRB(
          SdContentPaddingV2.horizontal,
          SdContentPaddingV2.listItemGap,
          SdContentPaddingV2.horizontal,
          SdContentPaddingV2.bottom(context, floatingNav: true),
        ),
        children: <Widget>[_card(ref)],
      ),
    );
  }

  Widget _card(WidgetRef ref) => switch (tab) {
    InsightsTab.weather => const WeatherCard(),
    InsightsTab.pressure => switch (ref.watch(correlationResultProvider)) {
      AsyncData<CorrelationResult>(value: final CorrelationResult value) =>
        PressureCard(result: value),
      // Nothing rather than a spinner: the engine resolves in a frame or two,
      // and a placeholder that flashes is louder than a card arriving late.
      _ => const SizedBox.shrink(),
    },
    InsightsTab.activity =>
      switch (ref.watch(exertionCorrelationResultProvider)) {
        AsyncData<ExertionCorrelationResult>(
          value: final ExertionCorrelationResult value,
        ) =>
          ActivityCard(result: value),
        _ => const SizedBox.shrink(),
      },
    InsightsTab.sleep => const SleepCard(),
  };
}
