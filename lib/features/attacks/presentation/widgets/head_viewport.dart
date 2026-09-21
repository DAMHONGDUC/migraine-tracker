import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../domain/enums/head_rotation_speed.dart';
import 'head_pose.dart';

/// Camera state stays separate from recorded pain locations.
typedef HeadViewport = ({double yaw, double pitch, double zoom});

final class HeadViewportUtils {
  const HeadViewportUtils._();

  static const double minZoom = 1;
  static const double maxZoom = 2;
  static const double zoomStep = 0.25;

  static const double maxPitch = 85;

  /// How far a drag turns the head, before the user's own rotation speed is
  /// applied to it.
  static const double degreesPerPoint = HeadPose.degreesPerPoint;

  /// [degreesPerPoint] as [speed] leaves it — the one place the setting is
  /// spent, so nothing else has to remember to apply it.
  static double degreesPerPointAt(HeadRotationSpeed speed) =>
      degreesPerPoint * speed.factor;
  static const double fieldOfView = 45 * vm.degrees2Radians;
  static const double framingMargin = 1.08;

  /// Where the head opens, and where Reset puts it back: as large as the
  /// viewport it is drawn in can hold it.
  ///
  /// **Measured per viewport, not a constant** (owner's rule, 2026-09-21). It
  /// used to be a flat 150%, picked against one phone, and a number picked
  /// that way is right on one screen and wrong on every other — an iPad gets a
  /// box a different shape as well as a bigger one, and a level that filled
  /// the phone leaves it half empty. The size the user asked for is "the
  /// biggest that fits", which is a thing the viewport can be asked rather
  /// than a thing to guess.
  ///
  /// **Why [minZoom] is nowhere near it.** At 100% the camera frames the
  /// head's bounding SPHERE, so the head — which is a good deal taller than it
  /// is round — sits inside a circle of air. This measures the head's own
  /// corners instead, at the two angles the picker rests at, so what touches
  /// the edge of the frame is the head rather than the space around it.
  ///
  /// **It fills the frame, controls and all** (owner's call, 2026-09-21). The
  /// zoom buttons float over the top of the viewport, so at this level they
  /// cover the crown rather than the air above it — which is the trade the
  /// owner took when asked: reserving that band for them costs the head more
  /// than it is worth, and it would open SMALLER on a phone than the flat 150%
  /// it replaces.
  static double fitZoom(vm.Aabb3 bounds, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) {
      return minZoom;
    }

    // Built at 100% because the projection is LINEAR in zoom: a point twice as
    // far from the centre of the frame at 200% as at 100% (asserted in
    // `head_scene_interaction_test.dart`). So one projection answers every
    // level, and the zoom that fits is the reciprocal of what 100% measures.
    final PerspectiveCamera camera = HeadViewportUtils.camera(bounds, size, 1);
    final Offset centre = Offset(size.width / 2, size.height / 2);
    double extentX = 0;
    double extentY = 0;

    // Both rest angles, because the Front/Back tabs turn the head without
    // touching the zoom: a level that fits the face and clips the nape is a
    // level that is wrong half the time. The model is not symmetric front to
    // back — the nose reaches further than the occiput — so the two differ.
    for (final double yaw in <double>[HeadPose.frontYaw, HeadPose.backYaw]) {
      final vm.Matrix4 pose = transform(bounds, (yaw: yaw, pitch: 0, zoom: 1));

      for (final vm.Vector3 corner in _corners(bounds)) {
        final Offset? point = camera.worldToScreen(
          pose.transformed3(corner),
          size,
        );

        if (point == null) continue;

        extentX = math.max(extentX, (point.dx - centre.dx).abs() / centre.dx);
        extentY = math.max(extentY, (point.dy - centre.dy).abs() / centre.dy);
      }
    }

    if (extentX <= 0 || extentY <= 0) return minZoom;

    return math.min(1 / extentX, 1 / extentY).clamp(minZoom, maxZoom);
  }

  /// The eight corners of [bounds] — the head's own box, not the sphere drawn
  /// round it.
  static Iterable<vm.Vector3> _corners(vm.Aabb3 bounds) sync* {
    for (final double x in <double>[bounds.min.x, bounds.max.x]) {
      for (final double y in <double>[bounds.min.y, bounds.max.y]) {
        for (final double z in <double>[bounds.min.z, bounds.max.z]) {
          yield vm.Vector3(x, y, z);
        }
      }
    }
  }

  static HeadViewport constrained(HeadViewport pose) => (
    yaw: pose.yaw,
    pitch: pose.pitch.clamp(-maxPitch, maxPitch),
    zoom: pose.zoom.clamp(minZoom, maxZoom),
  );

  static PerspectiveCamera camera(vm.Aabb3 bounds, Size size, double zoom) {
    final double radius = math.max((bounds.max - bounds.min).length / 2, 0.001);
    final double aspect = size.width / size.height;
    final double horizontal = 2 * math.atan(math.tan(fieldOfView / 2) * aspect);
    final double distance =
        radius /
        math.sin(math.min(fieldOfView, horizontal) / 2) *
        framingMargin;
    final vm.Vector3 center = bounds.center;

    return PerspectiveCamera(
      position: center + vm.Vector3(0, 0, distance),
      target: center,
      fovRadiansY:
          2 *
          math.atan(math.tan(fieldOfView / 2) / zoom.clamp(minZoom, maxZoom)),
      fovNear: math.max(distance - radius * 1.1, 0.001),
      fovFar: distance + radius * 2,
    );
  }

  static vm.Matrix4 transform(vm.Aabb3 bounds, HeadViewport pose) {
    final vm.Vector3 center = bounds.center;

    return vm.Matrix4.identity()
      ..translateByVector3(center)
      ..rotateX(pose.pitch * vm.degrees2Radians)
      ..rotateY(pose.yaw * vm.degrees2Radians)
      ..translateByVector3(-center);
  }
}
