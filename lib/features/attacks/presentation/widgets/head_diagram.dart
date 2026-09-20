import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart' show Node;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:system_design/index.dart';

import '../../../../core/widgets/app_loading_dots.dart';
import '../../domain/enums/head_region.dart';
import '../../domain/enums/head_rotation_speed.dart';
import 'head_pose.dart';
import 'head_region_geometry.dart';
import 'head_region_painter.dart';
import 'head_scene.dart';
import 'head_scene_store.dart';
import 'head_viewport.dart';

/// The head the user points at — one turnable solid where the device can draw
/// it, and the flat pair of drawings where it cannot.
///
/// **The two paths are not a migration.** Flutter GPU is a build flag and a
/// device capability, and a widget test has no GPU at all, so the flat diagram
/// is the answer whenever [HeadSceneStore] comes back empty. Both draw the same
/// fifteen areas and both pick them: a phone that cannot render a model still
/// has to be able to record where it hurts.
///
/// **While the model is still loading it draws a placeholder, never the flat
/// head** (owner's rule, 2026-09-18). The flat head used to fill that gap and
/// the user saw it blink past on every open — a drawing that appears and is
/// replaced a moment later reads as a glitch, not as a fallback. The flat pair
/// is now what a device answers with once loading has actually failed, and the
/// wait says "waiting" the way every other known-size wait in the app does.
class HeadDiagram extends StatefulWidget {
  const HeadDiagram({
    required this.selected,
    required this.view,
    this.yaw,
    this.pitch = 0,
    this.zoom = 1,
    this.rotationSpeed = HeadRotationSpeed.initial,
    this.expandScene = false,
    this.onPoseChanged,
    this.onInteractionStart,
    this.onAvailabilityChanged,
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
  final double pitch;
  final double zoom;

  /// The user's own rotation speed. It reaches the gesture surface and nothing
  /// else — the flat fallback has no turn to slow down.
  final HeadRotationSpeed rotationSpeed;

  /// Let the 3D picker use its whole slot; the SVG keeps its design ratio.
  final bool expandScene;
  final ValueChanged<HeadViewport>? onPoseChanged;
  final VoidCallback? onInteractionStart;
  final ValueChanged<bool>? onAvailabilityChanged;

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

  /// Whether the model has been tried and cannot be drawn here. Separate from
  /// a null template, because "not yet" and "never" are the two waits this
  /// widget answers differently.
  bool _unavailable = HeadSceneStore.unavailable;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) widget.onAvailabilityChanged?.call(_template != null);
    });
    if (_template != null || _unavailable) return;

    // Unawaited by shape, not by accident: nothing on this screen waits for a
    // model, and the placeholder is already on screen while it loads.
    HeadSceneStore.load().then((Node? node) {
      if (!mounted) return;

      setState(() {
        _template = node;
        _unavailable = node == null;
      });
      widget.onAvailabilityChanged?.call(node != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Node? template = _template;

    final Widget head = switch ((template, _unavailable)) {
      (final Node node, _) => HeadScene(
        template: node,
        pitch: widget.pitch,
        zoom: widget.zoom,
        rotationSpeed: widget.rotationSpeed,
        onPoseChanged: widget.onPoseChanged,
        onInteractionStart: widget.onInteractionStart,
        selected: widget.selected,
        yaw: widget.yaw ?? HeadPose.yawFor(widget.view),
        onRegionTapped: widget.onRegionTapped,
        onYawChanged: widget.onYawChanged,
      ),
      (null, false) => const _LoadingHead(),
      (null, true) => _FlatHead(
        selected: widget.selected,
        view: widget.view,
        onRegionTapped: widget.onRegionTapped,
      ),
    };

    if (template != null && widget.expandScene) {
      return SizedBox.expand(child: head);
    }
    return AspectRatio(
      aspectRatio: HeadRegionGeometry.aspectRatio,
      child: head,
    );
  }
}

/// The wait before the solid head arrives: the launch's own dots, centred in
/// the box the head will fill.
///
/// **The same animation as the splash, on purpose** (owner's rule,
/// 2026-09-19). Loading the model is the same kind of wait as launching — the
/// app holding still for something it cannot hurry — and a skeleton block here
/// said something different about it while also filling the picker with grey.
/// [AppLoadingDots] is the one owner of that look.
class _LoadingHead extends StatelessWidget {
  const _LoadingHead();

  /// The launch draws its dots at 40 raw pixels above `ScreenUtilInit`; this
  /// one is inside the app tree, so it scales with the screen like everything
  /// else on this step.
  static double get _dotsSize => SdSpacingConstant.r32;

  @override
  Widget build(BuildContext context) => AppLoadingDots(size: _dotsSize);
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
