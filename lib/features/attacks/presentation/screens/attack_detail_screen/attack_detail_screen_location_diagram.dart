part of 'attack_detail_screen.dart';

/// The logged head location, drawn rather than spelled out — the same
/// [HeadDiagram] the log flow's second tap uses, so a saved attack shows the
/// picture the user picked it from. It reads the attack; the row underneath
/// stays the way to change it.
class _LocationDiagram extends StatelessWidget {
  const _LocationDiagram({required this.location});

  final HeadLocation location;

  /// Small enough to sit above the rows rather than take the screen, unlike
  /// the log step where the diagram is the whole question.
  static double get height => SdSpacingConstant.h160;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: location.label(context.l10n),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: SdSpacingConstant.h16,
          bottom: SdSpacingConstant.h8,
        ),
        child: SizedBox(
          height: height,
          // Centred for LOOSE width: a tight ListView child overrides the
          // AspectRatio inside HeadDiagram, stretching the head across the row.
          child: Center(child: HeadDiagram(selected: location)),
        ),
      ),
    );
  }
}
