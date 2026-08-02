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
  static double get height => AppSpacingConstant.h160;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: location.label(context.l10n),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: AppSpacingConstant.h16,
          bottom: AppSpacingConstant.h8,
        ),
        child: SizedBox(
          height: height,
          // Centred so the diagram gets LOOSE width: a ListView hands its
          // children a tight one, and a tight box overrides the AspectRatio
          // inside HeadDiagram — the head came out stretched across the full
          // row. The log flow's Column centres by default, which is why only
          // this screen showed it.
          child: Center(child: HeadDiagram(selected: location)),
        ),
      ),
    );
  }
}
