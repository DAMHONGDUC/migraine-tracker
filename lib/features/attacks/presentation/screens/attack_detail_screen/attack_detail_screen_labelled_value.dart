part of 'attack_detail_screen.dart';

/// The "label … value" line both detail rows are built from.
///
/// **One widget, because the two rows must stay the same shape** — an editable
/// row and a read-only one differ by a chevron and a tap, never by how the
/// label and the value divide the line.
///
/// **The value is measured first, at its own width, and the label gets the
/// rest.** Two `Expanded` halves were the previous shape and they split the
/// line exactly 50/50 whatever was in them: on a 393pt screen that is 138.5pt
/// a side, and "Intensity" wants 148.5 — so a one-word label wrapped onto two
/// lines while the value beside it was the single character `7`. `Flexible`
/// does not fix that either: a flex child's share is computed from the free
/// space BEFORE its siblings are measured, so the slack a short value leaves
/// never reaches the label.
///
/// So the value is a non-flex child — laid out at its intrinsic width, which
/// `Row` does before it divides what is left — and the label is `Expanded`
/// over the remainder. The cap is what keeps the old no-overflow property:
/// without it a long value pushed the label past the edge, which is the 7.5px
/// overflow this row has had before.
class _LabelledValue extends StatelessWidget {
  const _LabelledValue({required this.label, required this.value});

  final String label;

  /// Already laid out by the caller — the plain text, or the text with its
  /// colour dot in front of it.
  final Widget value;

  /// Most of the line a value may take. **Half — exactly what the two
  /// `Expanded` halves gave it**, which is what makes this change strictly an
  /// improvement rather than a trade: a value that needs its whole half still
  /// gets it and the row looks as it always did, and a value that needs less
  /// hands the difference to the label instead of leaving a hole. A bigger
  /// fraction would have bought the long-value case at the cost of the label
  /// wrapping where it used not to.
  static const double valueMaxFraction = 0.5;

  /// The insets both rows give their `ListTile`, and the reason they give it
  /// one at all.
  ///
  /// **Material 3's default is `start: 16, end: 24`** — asymmetric on purpose
  /// in the spec, and measured on this screen as 16pt from the card's left
  /// edge to the label against 24pt from the chevron to its right edge. The
  /// owner read that as the row not being spaced between its own edges, which
  /// is exactly what it is. One gutter, the app's own, on both sides.
  ///
  /// Held here rather than typed into each row, because the two rows must
  /// divide their line identically and that includes the edges they divide it
  /// between.
  static EdgeInsets get tilePadding =>
      EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodyLarge,
            ),
          ),
          // The floor between them: the label ellipsizes into its own space
          // rather than up against the value.
          SizedBox(width: SdSpacingConstant.w8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * valueMaxFraction,
            ),
            child: value,
          ),
        ],
      ),
    );
  }
}
