part of 'history_filters_sheet.dart';

/// One axis of the sheet: its heading, then whatever draws its values.
class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
    this.first = false,
  });

  final String title;
  final Widget child;

  /// True for the top section, which takes the sheet's own gap rather than a separator of its own.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SdSectionHeaderV2(title, first: first),
        child,
      ],
    );
  }
}

/// The values of one axis as toggling chips, wrapping onto as many lines as they need.
class _ChipWrap<T> extends StatelessWidget {
  const _ChipWrap({
    required this.options,
    required this.isSelected,
    required this.labelBuilder,
    required this.onTap,
  });

  final List<T> options;
  final bool Function(T value) isSelected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SdSpacingConstant.w8,
      runSpacing: SdSpacingConstant.h8,
      children: <Widget>[
        for (final T option in options)
          SdSelectableChipV2(
            label: labelBuilder(option),
            selected: isSelected(option),
            onTap: () => onTap(option),
          ),
      ],
    );
  }
}
