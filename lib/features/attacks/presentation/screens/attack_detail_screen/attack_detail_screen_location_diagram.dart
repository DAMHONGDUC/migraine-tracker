part of 'attack_detail_screen.dart';

/// The logged head areas, drawn rather than spelled out.
class _LocationDiagram extends StatelessWidget {
  const _LocationDiagram({required this.regions});

  final List<HeadRegion> regions;

  /// Small enough to sit above the rows rather than take the screen, unlike the log step where the diagram is the whole question.
  static double get height => SdSpacingConstant.h160;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: regions.label(context.l10n),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: SdSpacingConstant.h16,
          bottom: SdSpacingConstant.h8,
        ),
        child: SizedBox(
          height: height,
          // Centred for LOOSE width: a tight ListView child overrides the AspectRatio inside HeadDiagram, stretching the head across the row.
          child: Center(
            child: HeadDiagram(
              selected: regions,
              view: HeadRegion.primaryView(regions),
            ),
          ),
        ),
      ),
    );
  }
}
