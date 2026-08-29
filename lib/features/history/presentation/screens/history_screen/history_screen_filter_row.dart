part of 'history_screen.dart';

/// The period filter pill row, first thing in each scrollable.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.count});

  final int count;

  /// Scroll offset past which the pill row is gone behind the app bar — the pill's own height plus its bottom padding.
  static double get scrolledPastExtent =>
      SdFilterPillV2.pillHeight + SdContentPaddingV2.listItemGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: SdContentPaddingV2.listItemGap),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: HistoryFilterChip(
          selected: ref.watch(historyPeriodProvider),
          count: count,
          onSelected: ref.read(historyPeriodProvider.notifier).select,
        ),
      ),
    );
  }
}
