part of 'history_screen.dart';

class _AttackList extends ConsumerWidget {
  const _AttackList({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
  });

  final List<Attack> attacks;

  /// Clears the app bar and the pinned filter strip. Whichever sliver comes first carries it; the ones under it start flush.
  final double topInset;

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int active = ref.watch(attackFiltersProvider).activeCount;
    final bool hasSummary = active > 0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (hasSummary)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              topInset,
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.listItemGap,
            ),
            sliver: SliverToBoxAdapter(
              child: ActiveFilterSummary(
                count: active,
                onClear: ref.read(attackFiltersProvider.notifier).reset,
              ),
            ),
          ),
        if (attacks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              // Already cleared by whatever sits above, when anything does.
              padding: EdgeInsets.only(top: hasSummary ? 0 : topInset),
              child: SdEmptyStateV2(
                icon: AppIconConstant.filter,
                message: context.l10n.historyEmptyFiltered,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              hasSummary ? 0 : topInset,
              SdContentPaddingV2.horizontal,
              bottomInset,
            ),
            sliver: SliverList.separated(
              itemCount: attacks.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: SdContentPaddingV2.listItemGap),
              itemBuilder: (BuildContext context, int index) =>
                  AttackTile(attack: attacks[index]),
            ),
          ),
      ],
    );
  }
}
