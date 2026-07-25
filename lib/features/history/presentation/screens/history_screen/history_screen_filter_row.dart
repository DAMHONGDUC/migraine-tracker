part of 'history_screen.dart';

/// The period filter pill row, first thing in each scrollable — below the
/// app bar (not in it), leading-aligned, and it stays visible when the
/// filter matches nothing so the user can always switch back. Once it
/// scrolls away, [HistoryScreen] shows the same pill in the app bar.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.count});

  final int count;

  /// Scroll offset past which the pill row is gone behind the app bar —
  /// the pill height plus its bottom padding.
  static double get scrolledPastExtent =>
      AppSpacingConstant.h34 + AppSpacingConstant.h12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h12),
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
