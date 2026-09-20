import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_pose.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Where the head is pointing, and — the part that cannot be eyeballed — which
/// screen side that puts the user's left on.
///
/// The camera maths below is the same `flutter_scene` code the widget runs, and
/// it needs no GPU: this is how the claim in `docs/HEAD_3D_PLAN.md` is checked
/// rather than asserted.
void main() {
  group('the angle', () {
    test('folds into half a turn either way', () {
      expect(HeadPose.normalize(0), 0);
      expect(HeadPose.normalize(190), -170);
      expect(HeadPose.normalize(-190), 170);
      expect(HeadPose.normalize(540), 180);
    });

    test('the quarter turn is where the view changes', () {
      expect(HeadPose.viewAt(0), HeadView.front);
      expect(HeadPose.viewAt(89), HeadView.front);
      expect(HeadPose.viewAt(90), HeadView.back);
      expect(HeadPose.viewAt(180), HeadView.back);
      expect(HeadPose.viewAt(-120), HeadView.back);
    });

    test('a snap takes the short way round', () {
      // 170 to the nape is ten degrees on, not three hundred and fifty back.
      expect(HeadPose.shortestTurn(170, HeadPose.backYaw), 180);
      expect(HeadPose.shortestTurn(-170, HeadPose.backYaw), -180);
      // And 190 back to the face carries on the same way rather than
      // unwinding: 360 is the face, reached in another 170 degrees.
      expect(HeadPose.shortestTurn(190, HeadPose.frontYaw), 360);
      expect(HeadPose.shortestTurn(10, HeadPose.frontYaw), 0);
    });
  });

  group('which side the user sees', () {
    /// The head is a metre tall and centred on the origin, the way the model
    /// is; the camera frames it exactly as `HeadScene` does.
    const Size view = Size(345, 428);

    Camera camera() => PerspectiveCamera.framing(
      vm.Aabb3.minMax(vm.Vector3(-0.4, -0.5, -0.5), vm.Vector3(0.4, 0.5, 0.5)),
      direction: vm.Vector3(0, 0, 1),
      margin: 1.25,
    );

    /// Where a point on the user's LEFT (-X, as `tool/head_model.py` builds it)
    /// lands on screen once the head is turned by [yaw].
    double screenXOfUserLeft(double yaw) {
      final vm.Vector3 point = vm.Matrix4.rotationY(
        yaw * vm.degrees2Radians,
      ).transformed3(vm.Vector3(-0.35, 0, 0));

      return camera().worldToScreen(point, view)!.dx;
    }

    test('face on, the user sees their own left on the RIGHT', () {
      // Which is where a real person's left is when you stand facing them. The
      // old flat front view was mirrored to dodge this; a solid cannot be.
      expect(screenXOfUserLeft(HeadPose.frontYaw), greaterThan(view.width / 2));
      expect(HeadPose.leftIsOnScreenLeft(HeadPose.frontYaw), isFalse);
    });

    test('turned around, it is back on the left', () {
      expect(screenXOfUserLeft(HeadPose.backYaw), lessThan(view.width / 2));
      expect(HeadPose.leftIsOnScreenLeft(HeadPose.backYaw), isTrue);
    });

    test('the labels flip on the same quarter turn the tiles do', () {
      for (final double yaw in <double>[0, 45, 89, 90, 135, 180, -91, -45]) {
        expect(
          HeadPose.leftIsOnScreenLeft(yaw),
          HeadPose.viewAt(yaw) == HeadView.back,
          reason: 'at $yaw the labels and the tiles must agree',
        );
      }
    });
  });
}
