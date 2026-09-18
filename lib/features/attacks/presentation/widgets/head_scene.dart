import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:system_design/common.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_region.dart';
import 'head_gesture_surface.dart';
import 'head_model_contract.dart';
import 'head_viewport.dart';

/// Rendering and picking share geometry, pose, camera and viewport.
class HeadScene extends StatefulWidget {
  const HeadScene({
    required this.template,
    required this.selected,
    required this.yaw,
    this.pitch = 0,
    this.zoom = 1,
    this.onRegionTapped,
    this.onYawChanged,
    this.onPoseChanged,
    this.onInteractionStart,
    super.key,
  });

  final Node template;
  final List<HeadRegion> selected;
  final double yaw;
  final double pitch;
  final double zoom;
  final ValueChanged<HeadRegion>? onRegionTapped;
  final ValueChanged<double>? onYawChanged;
  final ValueChanged<HeadViewport>? onPoseChanged;
  final VoidCallback? onInteractionStart;

  static Color get selectedTint =>
      Color.lerp(AppColors.surfaceElevated, AppColors.primary, 0.55)!;

  @override
  State<HeadScene> createState() => _HeadSceneState();
}

class _HeadSceneState extends State<HeadScene> {
  final Scene _scene = Scene();
  final Map<HeadRegion, List<PhysicallyBasedMaterial>> _materials =
      <HeadRegion, List<PhysicallyBasedMaterial>>{};
  late Node _head;
  late vm.Aabb3 _bounds;
  Camera? _camera;
  Size _viewSize = Size.zero;

  HeadViewport get _pose =>
      (yaw: widget.yaw, pitch: widget.pitch, zoom: widget.zoom);

  @override
  void initState() {
    super.initState();
    _loadTemplate();
    _scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.35, -0.55, -0.75),
      intensity: 2.4,
    );
  }

  void _loadTemplate() {
    _head = widget.template.clone();
    _bounds = _head.combinedWorldBounds!;
    _materials.clear();
    for (final Node node in HeadModelContract.nodes(_head)) {
      final HeadRegion? region = HeadModelContract.regionOf(node.name);
      final List<PhysicallyBasedMaterial> materials =
          <PhysicallyBasedMaterial>[];

      node.raycastable = region != null;
      for (final MeshPrimitive primitive
          in node.mesh?.primitives ?? const <MeshPrimitive>[]) {
        final PhysicallyBasedMaterial material = PhysicallyBasedMaterial()
          ..metallicFactor = 0
          ..roughnessFactor = 0.95
          ..baseColorFactor = _factor(
            region == null
                ? Color.lerp(
                    AppColors.surfaceElevated,
                    AppColors.textSecondary,
                    0.25,
                  )!
                : AppColors.surfaceElevated,
          );

        primitive.material = material;
        materials.add(material);
      }
      if (region != null) _materials[region] = materials;
    }
    _scene.add(_head);
    _applySelection();
    _applyPose();
  }

  void _applySelection() {
    for (final MapEntry<HeadRegion, List<PhysicallyBasedMaterial>> entry
        in _materials.entries) {
      final vm.Vector4 color = _factor(
        widget.selected.contains(entry.key)
            ? HeadScene.selectedTint
            : AppColors.surfaceElevated,
      );

      for (final PhysicallyBasedMaterial material in entry.value) {
        material.baseColorFactor = color;
      }
    }
  }

  void _applyPose() =>
      _head.localTransform = HeadViewportUtils.transform(_bounds, _pose);

  @override
  void didUpdateWidget(covariant HeadScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.template, oldWidget.template)) {
      _scene.remove(_head);
      _loadTemplate();
    } else {
      _applySelection();
      _applyPose();
    }
  }

  void _handleTap(Offset position) {
    final Camera? camera = _camera;
    final ValueChanged<HeadRegion>? callback = widget.onRegionTapped;

    if (camera == null || callback == null || _viewSize.isEmpty) return;
    SdLogger.action(
      LogTagConstant.attackLog,
      'Pick head surface',
      <String, Object?>{
        'x': position.dx,
        'y': position.dy,
        'zoom': widget.zoom,
      },
    );
    final SceneRaycastHit? hit = _scene.raycast(
      camera.screenPointToRay(position, _viewSize),
    );
    final HeadRegion? region = HeadModelContract.regionOf(hit?.node.name);

    if (region != null) callback(region);
    SdLogger.info(
      LogTagConstant.attackLog,
      'Head surface pick finished',
      <String, Object?>{'hit': region != null},
    );
  }

  void _changePose(HeadViewport pose) {
    if (widget.onPoseChanged != null) {
      widget.onPoseChanged!(pose);
    } else {
      widget.onYawChanged?.call(pose.yaw);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      _viewSize = constraints.biggest;
      if (_viewSize.isEmpty ||
          !_viewSize.width.isFinite ||
          !_viewSize.height.isFinite) {
        return const SizedBox.shrink();
      }
      _camera = HeadViewportUtils.camera(_bounds, _viewSize, widget.zoom);
      return ClipRect(
        child: HeadGestureSurface(
          pose: _pose,
          onChanged: widget.onPoseChanged == null && widget.onYawChanged == null
              ? null
              : _changePose,
          onStart: widget.onInteractionStart,
          onTap: widget.onRegionTapped == null ? null : _handleTap,
          child: SceneView(_scene, camera: _camera),
        ),
      );
    },
  );

  static vm.Vector4 _factor(Color color) =>
      vm.Vector4(color.r, color.g, color.b, color.a);
}
