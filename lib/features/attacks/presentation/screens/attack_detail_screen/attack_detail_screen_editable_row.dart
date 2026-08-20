part of 'attack_detail_screen.dart';

/// One "label … value ›" row of the detail screen.
///
/// **Both halves are `Expanded`, and the value never goes in `trailing`.**
/// A `ListTile` lays `trailing` out at its intrinsic width first and tightens
/// the title to what is left, so a value long enough — "Right forehead, Back
/// left, Back right", one ordinary answer now that location is a set of areas
/// — squeezed "Location" down to a column of single letters. Moving the value
/// into the title fixes that, and giving BOTH sides a flex is what stops it
/// coming back the other way as an overflow: a `Row` whose every child is
/// `Expanded` cannot overflow, whatever text either side is handed.
///
/// The label is short and the value is right-aligned, so half the width each
/// still reads as one line of "label ......... value".
class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  /// Optional colour dot shown *beside* the value — the value itself keeps
  /// the text token (colour never carries meaning through text).
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodyLarge,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          // The dot travels WITH the value, inside the same half. As a sibling
          // of the two Expandeds it pinned to the seam between them — marooned
          // mid-row, a column away from the number it belongs to.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (swatch != null) ...<Widget>[
                  SdColorDotV2(color: swatch!),
                  SizedBox(width: SdSpacingConstant.w8),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: SdIconV2(
        icon: Icons.chevron_right,
        size: SdSpacingConstant.r20,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
