import '../../domain/enums/head_region.dart';

/// Where the head is pointing, and which way round that puts the user's sides.
///
/// Pure maths on purpose: it is the half of the 3D diagram that can be tested
/// without a GPU, and the half that is easy to get wrong.
final class HeadPose {
  const HeadPose._();

  /// The model is built with the face on +Z and the user's LEFT on -X
  /// (`tool/head_model.py`), and the camera sits on +Z looking back at it, so
  /// an unturned head is the face.
  static const double frontYaw = 0;
  static const double backYaw = 180;

  /// A quarter turn is the silhouette: past it the user is looking at the back
  /// of the head, which is when the tiles underneath change with it.
  static const double _quarterTurn = 90;

  /// How far the head turns per point of drag. A full turn is a little over a
  /// screen width, so the back is a flick away without the head spinning out
  /// from under a thumb that only meant to tap.
  static const double degreesPerPoint = 0.8;

  static double yawFor(HeadView view) =>
      view == HeadView.front ? frontYaw : backYaw;

  static HeadView viewAt(double yaw) =>
      normalize(yaw).abs() < _quarterTurn ? HeadView.front : HeadView.back;

  /// [yaw] folded into (-180, 180].
  static double normalize(double yaw) {
    double value = yaw % 360;

    if (value > 180) value -= 360;
    if (value <= -180) value += 360;

    return value;
  }

  /// True while the user's left side is drawn on the screen's left — which is
  /// while the BACK of the head is facing, not the front.
  ///
  /// The model is an ordinary head rather than a mirror image, so looking at
  /// its face puts its left where a real person's left is when you face them:
  /// on your right. The old flat front view was drawn mirrored to avoid
  /// exactly that, and one solid cannot be mirrored on one side and not the
  /// other — so the L and R labels travel with the head instead.
  ///
  /// Measured, not reasoned: `head_pose_test.dart` projects a point on the
  /// model's left through the very camera the widget uses.
  static bool leftIsOnScreenLeft(double yaw) =>
      normalize(yaw).abs() >= _quarterTurn;

  /// The nearest angle equal to [to], measured from [from] — so a snap from
  /// 170° to the face turns 10° forward rather than 170° back.
  static double shortestTurn(double from, double to) =>
      from + normalize(to - from);
}
