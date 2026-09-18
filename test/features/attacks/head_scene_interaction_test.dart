import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_gesture_surface.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_model_contract.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_viewport.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  final vm.Aabb3 bounds = vm.Aabb3.minMax(
    vm.Vector3(-0.8, -1.1, -0.9),
    vm.Vector3(0.8, 1.1, 0.9),
  );

  test(
    'zoom preserves center and clip planes while increasing magnification',
    () {
      const Size size = Size(300, 420);
      final PerspectiveCamera normal = HeadViewportUtils.camera(
        bounds,
        size,
        1,
      );
      final PerspectiveCamera zoomed = HeadViewportUtils.camera(
        bounds,
        size,
        2,
      );
      final vm.Vector3 point = vm.Vector3(0.3, 0, 0);
      final double before =
          (normal.worldToScreen(point, size)!.dx - size.width / 2).abs();
      final double after =
          (zoomed.worldToScreen(point, size)!.dx - size.width / 2).abs();

      expect(after, closeTo(before * 2, 0.001));
      expect(normal.position, zoomed.position);
      expect(normal.fovNear, zoomed.fovNear);
      expect(normal.fovFar, zoomed.fovFar);
      expect(zoomed.worldToScreen(bounds.center, size), const Offset(150, 210));
    },
  );

  test('rest sphere fits narrow and wide viewports independently of yaw', () {
    for (final Size size in <Size>[
      const Size(160, 420),
      const Size(600, 220),
    ]) {
      final PerspectiveCamera camera = HeadViewportUtils.camera(
        bounds,
        size,
        1,
      );
      for (final double yaw in <double>[0, 45, 90, 180]) {
        final vm.Matrix4 transform = HeadViewportUtils.transform(bounds, (
          yaw: yaw,
          pitch: 85,
          zoom: 1,
        ));
        for (final double x in <double>[-0.8, 0.8]) {
          for (final double y in <double>[-1.1, 1.1]) {
            for (final double z in <double>[-0.9, 0.9]) {
              final Offset screen = camera.worldToScreen(
                transform.transformed3(vm.Vector3(x, y, z)),
                size,
              )!;
              expect(screen.dx, inInclusiveRange(0, size.width));
              expect(screen.dy, inInclusiveRange(0, size.height));
            }
          }
        }
      }
    }
  });

  test('the head starts three zoom steps in, on the ladder', () {
    // Owner's rule: framed to fit, the regions worth aiming at are small and
    // far from the thumb, so the head opens filling the frame instead.
    expect(
      HeadViewportUtils.defaultZoom,
      greaterThan(HeadViewportUtils.minZoom),
    );
    expect(
      HeadViewportUtils.defaultZoom,
      lessThanOrEqualTo(HeadViewportUtils.maxZoom),
    );
    // On the step ladder, so the minus button walks back to minZoom exactly
    // and the readout never shows a level the buttons cannot reach.
    final double steps =
        (HeadViewportUtils.defaultZoom - HeadViewportUtils.minZoom) /
        HeadViewportUtils.zoomStep;
    expect(steps, closeTo(steps.roundToDouble(), 1e-9));
  });

  test('pose bounds reject excessive magnification and pitch', () {
    expect(HeadViewportUtils.constrained((yaw: 400, pitch: 120, zoom: 3)), (
      yaw: 400.0,
      pitch: 85.0,
      zoom: 2.0,
    ));
    expect(HeadViewportUtils.constrained((yaw: -400, pitch: -120, zoom: 0.2)), (
      yaw: -400.0,
      pitch: -85.0,
      zoom: 1.0,
    ));
  });

  test('missing region contract is rejected before rendering', () {
    expect(() => HeadModelContract.validate(Node()), throwsFormatException);
  });

  testWidgets('tap selects once but drag and pinch never select', (
    WidgetTester tester,
  ) async {
    HeadViewport pose = (yaw: 0, pitch: 0, zoom: 1);
    int taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Center(
            child: SizedBox(
              width: 300,
              height: 420,
              child: HeadGestureSurface(
                pose: pose,
                onChanged: (HeadViewport next) => setState(() => pose = next),
                onTap: (Offset _) => taps++,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
    final Finder surface = find.byType(HeadGestureSurface);
    final Offset center = tester.getCenter(surface);

    await tester.tap(surface);
    expect(taps, 1);
    await tester.drag(surface, const Offset(60, 20));
    await tester.pump();
    expect(taps, 1);
    expect(pose.yaw, isNot(0));
    final double yaw = pose.yaw;
    final TestGesture first = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final TestGesture second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveBy(const Offset(-35, 0));
    await second.moveBy(const Offset(35, 0));
    await tester.pump();
    await first.moveBy(const Offset(-20, 0));
    await second.moveBy(const Offset(20, 0));
    await tester.pump();
    await second.up();
    await first.up();
    await tester.pump();
    expect(taps, 1);
    expect(pose.zoom, greaterThan(1));
    expect(pose.yaw, yaw);
    await tester.tap(surface);
    expect(taps, 2);
  });

  testWidgets('two stationary fingers never produce a region tap', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeadGestureSurface(
          pose: (yaw: 0, pitch: 0, zoom: 1),
          onTap: (Offset _) => taps++,
          onChanged: (HeadViewport _) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    final TestGesture first = await tester.startGesture(
      const Offset(150, 150),
      pointer: 1,
    );
    final TestGesture second = await tester.startGesture(
      const Offset(200, 150),
      pointer: 2,
    );
    await second.up();
    await first.up();
    expect(taps, 0);
  });
  testWidgets('drag follows the finger and retains updates between frames', (
    WidgetTester tester,
  ) async {
    HeadViewport pose = (yaw: 0, pitch: 0, zoom: 1);
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              HeadGestureSurface(
                pose: pose,
                onChanged: (HeadViewport next) => setState(() => pose = next),
                child: const SizedBox.expand(),
              ),
        ),
      ),
    );
    final TestGesture drag = await tester.startGesture(const Offset(200, 200));
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    final double startYaw = pose.yaw;
    for (int i = 0; i < 3; i++) {
      await drag.moveBy(const Offset(20, 0));
    }
    expect(
      pose.yaw,
      closeTo(startYaw - 60 * HeadViewportUtils.degreesPerPoint, 0.001),
    );
    const Size size = Size(300, 420);
    final Camera camera = HeadViewportUtils.camera(bounds, size, 1);
    final vm.Vector3 front = vm.Vector3(0, 0, 0.9);
    final Offset projected = camera.worldToScreen(
      HeadViewportUtils.transform(bounds, pose).transformed3(front),
      size,
    )!;
    expect(
      projected.dx,
      greaterThan(size.width / 2),
      reason: 'Dragging right moves the front surface right on screen.',
    );
    await tester.pump();
    await drag.up();

    final TestGesture down = await tester.startGesture(const Offset(200, 200));
    await down.moveBy(const Offset(0, 30));
    await tester.pump();
    await down.moveBy(const Offset(0, 60));
    await down.moveBy(const Offset(0, 60));
    expect(pose.pitch, 85);
    final Offset lowered = camera.worldToScreen(
      HeadViewportUtils.transform(bounds, pose).transformed3(front),
      size,
    )!;
    expect(lowered.dy, greaterThan(size.height / 2));
    await down.up();
    await tester.pump();
  });
}
