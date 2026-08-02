part of 'history_screen.dart';

class _AttackList extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          if (attacks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SdEmptyStateV2(
                icon: Icons.filter_alt_outlined,
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
                    SizedBox(height: SdSpacingV2.h8),
                itemBuilder: (context, index) =>
                    AttackTile(attack: attacks[index]),
              ),
            ),
        ],
      ),
    );
  }
}
