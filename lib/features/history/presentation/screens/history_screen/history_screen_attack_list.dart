part of 'history_screen.dart';

class _AttackList extends ConsumerWidget {
  const _AttackList({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
    required this.onPastFilterChanged,
  });

  final List<Attack> attacks;
  final double topInset;
  final double bottomInset;

  /// Reports whether the filter pill has scrolled out behind the app bar.
  final ValueChanged<bool> onPastFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null while premium — no limit, so nothing to show.
    final int? used = ref.watch(attacksUsedProvider);

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        onPastFilterChanged(
          notification.metrics.pixels > _FilterRow.scrolledPastExtent,
        );
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // Flush under the app bar — no gap between the bar and the content.
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              topInset,
              SdContentPaddingV2.horizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(count: attacks.length),
            ),
          ),
          // Under the filter row rather than above it: the pill has to start at offset 0 or `_FilterRow.scrolledPastExtent` fires while it is still on screen.
          if (used != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                SdContentPaddingV2.horizontal,
                0,
                SdContentPaddingV2.horizontal,
                SdContentPaddingV2.listItemGap,
              ),
              sliver: SliverToBoxAdapter(
                child: FreeLimitProgress(
                  used: used,
                  limit: PremiumLimitConstant.attacks,
                  titleBuilder: (int left) => context.l10n.freeLimitAttacks(
                    left,
                  ),
                ),
              ),
            ),
          if (attacks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SdEmptyStateV2(
                icon: AppIconConstant.filter,
                message: context.l10n.historyEmptyFiltered,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                SdContentPaddingV2.horizontal,
                0,
                SdContentPaddingV2.horizontal,
                bottomInset,
              ),
              sliver: SliverList.separated(
                itemCount: attacks.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: SdContentPaddingV2.listItemGap),
                itemBuilder: (context, index) =>
                    AttackTile(attack: attacks[index]),
              ),
            ),
        ],
      ),
    );
  }
}
