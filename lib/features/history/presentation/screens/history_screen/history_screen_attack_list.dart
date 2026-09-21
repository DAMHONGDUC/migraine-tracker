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
    // Where the free plan stops reading: the first row behind the window, or
    // -1 when none of them is. The list is newest-first and the window cuts on
    // time, so every locked row is contiguous from here to the end — which is
    // what makes one index enough to place the banner.
    final DateTime? from = ref.watch(freeHistoryStartProvider);
    final int firstLocked = attacks.indexWhere(
      (Attack attack) => AttackWindow.locks(attack, from),
    );
    final bool hasBanner = firstLocked >= 0;

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
            // One list with the banner as an item, not three slivers with
            // hand-padded seams: the separator then spaces the banner from the
            // rows either side of it exactly as it spaces two rows.
            sliver: SliverList.separated(
              itemCount: attacks.length + (hasBanner ? 1 : 0),
              separatorBuilder: (_, _) =>
                  SizedBox(height: SdContentPaddingV2.listItemGap),
              itemBuilder: (BuildContext context, int index) {
                if (hasBanner && index == firstLocked) {
                  return const FreeHistoryBanner();
                }

                return AttackTile(
                  attack:
                      attacks[hasBanner && index > firstLocked
                          ? index - 1
                          : index],
                );
              },
            ),
          ),
      ],
    );
  }
}
