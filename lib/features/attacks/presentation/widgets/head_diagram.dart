import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart' show Node;
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/enums/head_region.dart';
import 'head_pose.dart';
import 'head_region_geometry.dart';
import 'head_region_painter.dart';
import 'head_scene.dart';
import 'head_scene_store.dart';

/// The head the user points at — one turnable solid where the device can draw
/// it, and the flat pair of drawings where it cannot.
///
/// **The two paths are not a migration.** Flutter GPU is a build flag and a
/// device capability, and a widget test has no GPU at all, so the flat diagram
/// is the answer whenever [HeadSceneStore] comes back empty. Both draw the same
/// fifteen areas and both pick them: a phone that cannot render a model still
/// has to be able to record where it hurts.
class HeadDiagram extends StatefulWidget {
  const HeadDiagram({
    required this.selected,
    required this.view,
    this.yaw,
    this.onRegionTapped,
    this.onYawChanged,
    super.key,
  });

  final List<HeadRegion> selected;

  /// Which side is being shown. The flat path draws it; the solid one uses it
  /// only as the angle to rest at when [yaw] is not given.
  final HeadView view;

  /// Degrees about the vertical axis, for callers that own the turn. Null
  /// rests at whatever [view] asks for.
  final double? yaw;

  final ValueChanged<HeadRegion>? onRegionTapped;

  /// Null makes the head read-only: it reports an answer instead of asking.
  final ValueChanged<double>? onYawChanged;

  static const Map<HeadView, String> assets = <HeadView, String>{
    HeadView.front: 'assets/images/head_front.svg',
    HeadView.back: 'assets/images/head_back.svg',
  };

  @override
  State<HeadDiagram> createState() => _HeadDiagramState();
}

class _HeadDiagramState extends State<HeadDiagram> {
  Node? _template = HeadSceneStore.template;

  @override
  void initState() {
    super.initState();

    if (_template != null || HeadSceneStore.unavailable) return;

    // Unawaited by shape, not by accident: nothing on this screen waits for a
    // model, and the flat diagram is already on screen while it loads.
    HeadSceneStore.load().then((Node? node) {
      if (mounted && node != null) setState(() => _template = node);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Node? template = _template;

    return AspectRatio(
      aspectRatio: HeadRegionGeometry.aspectRatio,
      child: template == null
          ? _FlatHead(
              selected: widget.selected,
              view: widget.view,
              onRegionTapped: widget.onRegionTapped,
            )
          : HeadScene(
              template: template,
              selected: widget.selected,
              yaw: widget.yaw ?? HeadPose.yawFor(widget.view),
              onRegionTapped: widget.onRegionTapped,
              onYawChanged: widget.onYawChanged,
            ),
    );
  }
}

/// The original pair of drawings: line art from an SVG over a painted fill.
///
/// It stays pickable rather than becoming a picture. A device without Flutter
/// GPU is not a device whose owner stops having migraines, and half a picker is
/// worse than an older one.
class _FlatHead extends StatelessWidget {
  const _FlatHead({
    required this.selected,
    required this.view,
    required this.onRegionTapped,
  });

  final List<HeadRegion> selected;
  final HeadView view;
  final ValueChanged<HeadRegion>? onRegionTapped;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<HeadRegion>? onTapped = onRegionTapped;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        return GestureDetector(
          // Opaque, not deferToChild: the SVG is mostly transparent, so hit-testing the child would only ever catch the strokes.
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapped == null
              ? null
              : (TapUpDetails details) {
                  final HeadRegion? region = HeadRegionGeometry.hitTest(
                    details.localPosition,
                    view,
                    size,
                  );
                  // A tap that missed the head does nothing. Snapping to the nearest area would log a place the user did not point at.
                  if (region != null) onTapped(region);
                },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            // SizedBox.expand is load bearing.
            child: SizedBox.expand(
              key: ValueKey<HeadView>(view),
              child: CustomPaint(
                // The key is on the SizedBox above: the switcher's direct child is what has to change identity to cross-fade.
                painter: HeadRegionPainter(view: view, selected: selected),
                // Fill keeps the artwork aligned with the painter's design box.
                child: SvgPicture.asset(
                  HeadDiagram.assets[view]!,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
