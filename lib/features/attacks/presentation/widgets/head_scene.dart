import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:system_design/common.dart';
// Prefixed: flutter_scene speaks vector_math's 32-bit Matrix4, and
// package:flutter/material.dart brings the 64-bit one of the same name.
import 'package:vector_math/vector_math.dart' as vm;

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_region.dart';
import 'head_pose.dart';

/// The head as one solid the user turns, drawn by `flutter_scene`.
///
/// **One mesh node per region, and that is what makes the answer exact.** The
/// model carries a node called `region_<enum name>` for each [HeadRegion], so
/// a ray that hits a node *is* the answer — nothing sits between what is drawn
/// and what is picked to drift apart. The face — brows, eyes, lips, ears — is
/// one `features` node with `raycastable` off, so a brow never eats the tap
/// meant for the eye under it.
///
/// The camera frames the model's bounding sphere once and never moves again.
/// A sphere is the same size from every angle, so the head keeps its size and
/// its place however far it is turned — the owner's rule that the head never
/// moves, kept by construction rather than by watching for it.
class HeadScene extends StatefulWidget {
  const HeadScene({
    required this.template,
    required this.selected,
    required this.yaw,
    this.onRegionTapped,
    this.onYawChanged,
    super.key,
  });

  /// The loaded model, from [HeadSceneStore]. Cloned per widget, so two heads
  /// on screen never share a highlight.
  final Node template;

  final List<HeadRegion> selected;

  /// Degrees about the vertical axis. 0 is the face; see [HeadPose].
  final double yaw;

  final ValueChanged<HeadRegion>? onRegionTapped;

  /// Called as a drag turns the head. Null makes it read-only — the detail
  /// screen, where the head reports an answer rather than asking for one.
  final ValueChanged<double>? onYawChanged;

  /// What a picked area is painted: the accent mixed INTO the surface rather
  /// than laid over it. The flat diagram filled at 0.45 alpha for the same
  /// reason — a solid accent block on a dark head reads as a sticker stuck on
  /// it rather than as a part of it lighting up.
  static Color get selectedTint =>
      Color.lerp(AppColors.surfaceElevated, AppColors.primary, 0.55)!;

  /// How far from the head the camera sits, as a multiple of the radius it has
  /// to fit. Above 1 is padding; a portrait view needs some, because the
  /// framing fits the vertical field of view and ours is the narrow one.
  static const double cameraMargin = 1.25;

  @override
  State<HeadScene> createState() => _HeadSceneState();
}

class _HeadSceneState extends State<HeadScene> {
  final Scene _scene = Scene();
  final Map<HeadRegion, List<PhysicallyBasedMaterial>> _materials =
      <HeadRegion, List<PhysicallyBasedMaterial>>{};

  late final Node _head;
  Camera? _camera;
  Size _viewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _head = widget.template.clone();
    _dressNodes();
    _scene
      ..add(_head)
      ..directionalLight = DirectionalLight(
        // Down and across from the front, so the brow and the nose cast the
        // shading that tells the head from an oval. Calm: one light, no specular
        // highlight to flash as the head turns (hard rule 3).
        direction: vm.Vector3(-0.35, -0.55, -0.75),
        intensity: 2.4,
      );
    _applySelection();
    _applyYaw();
    _frameCamera();
  }

  /// Gives every region its own material, so tinting one tints one, and takes
  /// the face out of the ray's way.
  void _dressNodes() {
    final List<String> missing = <String>[];

    for (final HeadRegion region in HeadRegion.values) {
      final Node? node = _head.getChildByName(_nodeName(region));

      if (node == null) {
        missing.add(region.name);
        continue;
      }

      final List<PhysicallyBasedMaterial> materials =
          <PhysicallyBasedMaterial>[];

      for (final MeshPrimitive primitive in node.mesh?.primitives ?? const <MeshPrimitive>[]) {
        final PhysicallyBasedMaterial material = PhysicallyBasedMaterial()
          ..metallicFactor = 0
          ..roughnessFactor = 0.95;

        primitive.material = material;
        materials.add(material);
      }

      _materials[region] = materials;
    }

    final Node? features = _head.getChildByName(featuresNode);

    if (features != null) {
      // It renders and is transparent to rays: the enum has no word for a brow
      // or an ear, so a tap on one belongs to the region underneath.
      features.raycastable = false;

      for (final MeshPrimitive primitive in features.mesh?.primitives ?? const <MeshPrimitive>[]) {
        primitive.material = PhysicallyBasedMaterial()
          ..metallicFactor = 0
          ..roughnessFactor = 1
          ..baseColorFactor = _factor(AppColors.textSecondary);
      }
    }

    if (missing.isNotEmpty) {
      // Not fatal — the rest of the head still picks — but it is a model that
      // no longer matches the enum, which is a release away from a dead area.
      SdLogger.warning(
        LogTagConstant.attackLog,
        'Head model is missing nodes',
        missing.join(', '),
      );
    }
  }

  void _applySelection() {
    for (final MapEntry<HeadRegion, List<PhysicallyBasedMaterial>> entry
        in _materials.entries) {
      final vm.Vector4 colour = widget.selected.contains(entry.key)
          ? _factor(HeadScene.selectedTint)
          : _factor(AppColors.surfaceElevated);

      for (final PhysicallyBasedMaterial material in entry.value) {
        material.baseColorFactor = colour;
      }
    }
  }

  void _applyYaw() =>
      _head.localTransform = vm.Matrix4.rotationY(widget.yaw * vm.degrees2Radians);

  /// Framed once, at rest, from the AABB's bounding sphere — which no rotation
  /// can grow. That is the whole reason the head does not swell and shrink as
  /// it turns.
  void _frameCamera() {
    final vm.Aabb3? bounds = _head.combinedWorldBounds;

    if (bounds == null) return;

    _camera = PerspectiveCamera.framing(
      bounds,
      // +Z, the side the face is on.
      direction: vm.Vector3(0, 0, 1),
      margin: HeadScene.cameraMargin,
    );
  }

  @override
  void didUpdateWidget(covariant HeadScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.selected, widget.selected)) _applySelection();
    if (oldWidget.yaw != widget.yaw) _applyYaw();
  }

  void _handleTap(TapUpDetails details) {
    final ValueChanged<HeadRegion>? onTapped = widget.onRegionTapped;
    final Camera? camera = _camera;

    if (onTapped == null || camera == null || _viewSize.isEmpty) return;

    final SceneRaycastHit? hit = _scene.raycast(
      camera.screenPointToRay(details.localPosition, _viewSize),
    );
    final HeadRegion? region = _regionOf(hit?.node.name);

    // A tap that missed the head, or landed on the face, does nothing. Snapping
    // to the nearest area would log a place the user did not point at.
    if (region != null) onTapped(region);
  }

  void _handleDrag(DragUpdateDetails details) {
    final ValueChanged<double>? onYawChanged = widget.onYawChanged;

    if (onYawChanged == null) return;

    onYawChanged(widget.yaw + details.delta.dx * HeadPose.degreesPerPoint);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      _viewSize = constraints.biggest;

      return GestureDetector(
        // Opaque: most of this box is the background beside a round head, and
        // a tap there still has to be a miss rather than nothing at all.
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onRegionTapped == null ? null : _handleTap,
        onHorizontalDragUpdate: widget.onYawChanged == null ? null : _handleDrag,
        child: SceneView(_scene, camera: _camera),
      );
    },
  );
}

/// The node name a region is drawn as. The model is generated from this same
/// spelling by `tool/head_model.py`, and `head_model_test.dart` compares the
/// two sets in both directions.
String _nodeName(HeadRegion region) => 'region_${region.name}';

/// The one node that is drawn and never picked.
const String featuresNode = 'features';

HeadRegion? _regionOf(String? nodeName) {
  if (nodeName == null) return null;

  for (final HeadRegion region in HeadRegion.values) {
    if (_nodeName(region) == nodeName) return region;
  }

  return null;
}

vm.Vector4 _factor(Color color) =>
    vm.Vector4(color.r, color.g, color.b, color.a);
