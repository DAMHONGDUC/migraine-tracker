part of 'attack_detail_screen.dart';

/// The logged head areas, drawn rather than spelled out.
///
/// **The head fills this band** (owner's rule, 2026-09-21). The band's height
/// is what it was; what changed is that the head now reaches the top and
/// bottom of it instead of floating in the middle. At zoom 1 the camera frames
/// the head's bounding SPHERE, so a taller-than-round thing sat inside a ring
/// of air and rendered at about 60% of its slot — passing no zoom asks
/// [HeadScene] for the level the box can actually hold (`fitZoom`, measured,
/// the same answer the log step opens on). `expandScene` hands it the whole
/// row for that measurement rather than the ratio-shaped column inside it; the
/// fit takes the smaller axis, so the head still keeps its shape and the extra
/// width is simply air either side.
///
/// **Tapping the head opens the same sheet the Location row opens** (owner's
/// rule, 2026-09-21). It is the picker's own "two doors onto one answer" idiom
/// carried onto this screen: the head is the biggest thing above the rows and
/// the one a user reaches for when an area is wrong, and a drawing that only
/// reports is a drawing they tap and nothing happens. The row below keeps its
/// `›`, which is where the affordance is stated — the head is the shortcut,
/// not the only way in.
class _LocationDiagram extends StatelessWidget {
  const _LocationDiagram({required this.regions, required this.onTap});

  final List<HeadRegion> regions;

  /// Opens the edit sheet. Required rather than nullable: every attack's areas
  /// are editable, including an attack that recorded none.
  final VoidCallback onTap;

  /// Small enough to sit above the rows rather than take the screen, unlike the log step where the diagram is the whole question.
  static double get height => SdSpacingConstant.h160;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: regions.label(context.l10n),
      button: true,
      excludeSemantics: true,
      // Opaque, and on the whole band rather than on the head: the head's own
      // surface is what the 3D and flat paths hit-test, and the loading dots
      // hit-test nothing at all — a tap beside the drawing, or one taken while
      // the model is still arriving, has to reach this too.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            top: SdSpacingConstant.h16,
            bottom: SdSpacingConstant.h8,
          ),
          child: SizedBox(
            height: height,
            // Centred for LOOSE width: the flat fallback keeps the AspectRatio inside HeadDiagram, and a tight ListView child would override it and stretch the drawing across the row.
            child: Center(
              child: HeadDiagram(
                selected: regions,
                view: HeadRegion.primaryView(regions),
                expandScene: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
