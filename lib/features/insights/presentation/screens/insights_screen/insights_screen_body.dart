part of 'insights_screen.dart';

/// Keeps every tab that has been opened alive behind the one on screen.
///
/// **An `IndexedStack`, so switching tabs does not throw the last one away.**
/// A `switch` that built only the selected card unmounted the others, and
/// coming back rebuilt from nothing: the scroll offset was gone, every chart
/// replayed its entry animation, and the card read as reloading. The provider
/// data was never the problem — none of these providers is `autoDispose` —
/// which is why the reload looked like one but never refetched.
///
/// **Lazily, though: a tab is built the first time it is selected, not
/// before.** Mounting all four up front would fire a weather fetch, a
/// forecast fetch and two HealthKit reads on a screen showing one card — the
/// eager cost the tabbed layout exists to avoid.
class _TabBody extends ConsumerStatefulWidget {
  const _TabBody({required this.tabs, required this.selected});

  final List<InsightsTab> tabs;
  final InsightsTab selected;

  @override
  ConsumerState<_TabBody> createState() => _TabBodyState();
}

class _TabBodyState extends ConsumerState<_TabBody> {
  /// Every tab opened so far. Grows, never shrinks — that is what "keeps its
  /// state" means, and four cards is not a memory problem.
  final Set<InsightsTab> _opened = <InsightsTab>{};

  @override
  void initState() {
    super.initState();
    _opened.add(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _TabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recorded here rather than in build: build must not have side effects,
    // and this is the only place the selection actually changes.
    _opened.add(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.tabs.indexOf(widget.selected),
      // Expand, or the stack takes the height of its tallest child and the
      // scroll views inside get unbounded constraints.
      sizing: StackFit.expand,
      children: <Widget>[
        for (final InsightsTab tab in widget.tabs)
          if (_opened.contains(tab))
            _TabCard(tab: tab)
          else
            const SizedBox.shrink(),
      ],
    );
  }
}

/// One tab's card, scrollable and refreshable.
///
/// **Each tab waits only on what it draws.** The screen used to hold every
/// card behind one `switch` on both correlation providers, so the weather —
/// which needs neither — was blank until the engines had run.
class _TabCard extends ConsumerWidget {
  const _TabCard({required this.tab});

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
        // Its own controller per tab, kept by the IndexedStack above — which
        // is what makes a tab come back where it was left.
        key: PageStorageKey<InsightsTab>(tab),
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
