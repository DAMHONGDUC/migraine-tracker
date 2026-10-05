part of 'history_screen.dart';

/// Every History axis in one sheet, the same [_Axis] list the strip draws. Pops the draft on Apply; null when closed without it.
class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({required this.initial, required this.axes});

  /// The filters on now, so the sheet opens where the strip is.
  final AttackFilters initial;

  final List<_Axis<Object?>> axes;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late AttackFilters _draft = widget.initial;

  void _update(AttackFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    return AllFiltersSheet(
      sections: <Widget>[
        for (final _Axis<Object?> axis in widget.axes)
          axis.section(_draft, _update),
      ],
      onApply: () => Navigator.of(context).pop(_draft),
      onClear: _draft.isDefault
          ? null
          : () => _update(const AttackFilters()),
    );
  }
}

/// Sheets expose their opener as `.show(context)` (CLAUDE.md § Code style).
extension _HistoryFilterSheetExt on _HistoryFilterSheet {
  Future<AttackFilters?> show(BuildContext context) =>
      showSdBottomSheetV2<AttackFilters>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
