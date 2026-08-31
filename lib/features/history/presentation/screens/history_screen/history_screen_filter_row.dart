part of 'history_screen.dart';

/// The filter pill row, first thing in each scrollable.
class _FilterRow extends StatelessWidget {
  const _FilterRow();

  /// Scroll offset past which the pill row is gone behind the app bar — the pill's own height plus its bottom padding.
  static double get scrolledPastExtent =>
      SdFilterPillV2.pillHeight + SdContentPaddingV2.listItemGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SdContentPaddingV2.listItemGap),
      child: const Align(
        alignment: AlignmentDirectional.centerStart,
        child: HistoryFiltersPill(),
      ),
    );
  }
}
