import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'head_pose.dart';

/// Camera state stays separate from recorded pain locations.
typedef HeadViewport = ({double yaw, double pitch, double zoom});

final class HeadViewportUtils {
  const HeadViewportUtils._();

  static const double minZoom = 1;
  static const double maxZoom = 2;
  static const double zoomStep = 0.25;

  /// Where the head starts, and where Reset puts it back.
  ///
  /// **Not [minZoom]** (owner's rule): framed to fit, the head sits in the
  /// middle of the viewport with air all round it, and the regions a user is
  /// actually aiming at — temple, eye, jaw — are small targets a long way from
  /// the thumb. Three steps in fills the frame with the head itself, so the
  /// first tap lands without anyone having to zoom in first.
  ///
  /// On the [zoomStep] ladder on purpose (1 + 3 x 0.25), so the minus button
  /// walks straight back down to [minZoom] and the readout never shows a level
  /// the buttons cannot reach.
  static const double defaultZoom = 1.75;
  static const double maxPitch = 85;
  static const double degreesPerPoint = HeadPose.degreesPerPoint;
  static const double fieldOfView = 45 * vm.degrees2Radians;
  static const double framingMargin = 1.08;

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
