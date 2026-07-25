part of 'history_screen.dart';

/// Chart mode — same filtered data as the list.
class _ChartView extends StatelessWidget {
  const _ChartView({
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
              AppSpacingConstant.w16,
              topInset,
              AppSpacingConstant.w16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _FilterRow(count: attacks.length),
            ),
          ),
          if (attacks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_outlined,
                message: context.l10n.historyEmptyFiltered,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacingConstant.w16,
                0,
                AppSpacingConstant.w16,
                bottomInset + AppSpacingConstant.h16,
              ),
              sliver: SliverToBoxAdapter(child: _Charts(attacks: attacks)),
            ),
        ],
      ),
    );
  }
}
