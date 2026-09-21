import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_gesture_surface.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_model_contract.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_geometry.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_region_picker.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_scene.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_scene_store.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_viewport.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
        ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('real head renders and remains pickable at every view and zoom', (
    WidgetTester tester,
  ) async {
    final GlobalKey previewKey = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 350));
      final RenderRepaintBoundary boundary =
          previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['screenshots'] ??= <dynamic>[];
      (binding.reportData!['screenshots']! as List<dynamic>).add(
        <String, dynamic>{
          'screenshotName': name,
          'bytes': bytes!.buffer.asUint8List().toList(),
        },
      );
    }

    final Node? template = await HeadSceneStore.load();
    final Set<HeadRegion> picked = <HeadRegion>{};
    final Scene scene = Scene();
    const Size viewport = Size(320, 400);
    List<HeadRegion> selected = <HeadRegion>[HeadRegion.templeL];
    double? pickerHeight;
    late StateSetter resizePicker;

    expect(
      template,
      isNotNull,
      reason:
          'This test must render 3D, never silently pass on the SVG fallback.',
    );
    final Node head = template!.clone();
    final vm.Aabb3 bounds = head.combinedWorldBounds!;
    for (final Node node in HeadModelContract.nodes(head)) {
      node.raycastable = HeadModelContract.regionOf(node.name) != null;
    }
    scene.add(head);
    for (final double zoom in <double>[1, 2]) {
      final Camera camera = HeadViewportUtils.camera(bounds, viewport, zoom);
      final Set<HeadRegion> pickedAtZoom = <HeadRegion>{};
      for (final double yaw in <double>[0, 45, 90, 135, 180, 225, 270, 315]) {
        for (final double pitch in <double>[-85, -25, 0, 25, 85]) {
          head.localTransform = HeadViewportUtils.transform(bounds, (
            yaw: yaw,
            pitch: pitch,
            zoom: zoom,
          ));
          for (double y = 4; y < viewport.height; y += 8) {
            for (double x = 4; x < viewport.width; x += 8) {
              final SceneRaycastHit? hit = scene.raycast(
                camera.screenPointToRay(Offset(x, y), viewport),
              );
              final HeadRegion? region = HeadModelContract.regionOf(
                hit?.node.name,
              );
              if (region != null) pickedAtZoom.add(region);
            }
          }
        }
      }
      expect(
        pickedAtZoom,
        HeadRegion.values.toSet(),
        reason: 'Every region must be reachable at zoom $zoom',
      );
      picked.addAll(pickedAtZoom);
    }
    expect(picked.length, 15);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          builder: (BuildContext context, Widget? child) =>
              RepaintBoundary(key: previewKey, child: child!),
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SafeArea(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  resizePicker = setState;
                  return Align(
                    child: SizedBox(
                      height: pickerHeight,
                      child: HeadRegionPicker(
                        selected: selected,
                        onChanged: (List<HeadRegion> value) =>
                            setState(() => selected = value),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HeadScene), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 350));
    await capture('head-front');
    final Rect surfaceRect = tester.getRect(find.byType(HeadGestureSurface));
    expect(
      surfaceRect.width,
      tester.getSize(find.byType(HeadRegionPicker)).width,
      reason: 'The L/R labels must not narrow the 3D viewport.',
    );
    final SceneView rendered = tester.widget<SceneView>(find.byType(SceneView));
    Offset? nosePoint;
    for (double y = 4; y < surfaceRect.height && nosePoint == null; y += 4) {
      for (double x = 4; x < surfaceRect.width; x += 4) {
        final Offset point = Offset(x, y);
        final vm.Ray ray = rendered.camera!.screenPointToRay(
          point,
          surfaceRect.size,
        );
        final SceneRaycastHit? hit = rendered.scene!.raycast(ray);
        if (HeadModelContract.regionOf(hit?.node.name) == HeadRegion.nose) {
          expect(
            rendered.scene!.raycastAll(ray).first.node.name,
            hit!.node.name,
          );
          nosePoint = point;
          break;
        }
      }
    }
    expect(nosePoint, isNotNull);
    await tester.tapAt(surfaceRect.topLeft + nosePoint!);
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.templeL, HeadRegion.nose]);
    await tester.tapAt(surfaceRect.topLeft + nosePoint);
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.templeL]);
    await tester.tapAt(surfaceRect.topLeft + const Offset(2, 2));
    await tester.pump();
    expect(selected, <HeadRegion>[HeadRegion.templeL]);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(tester.widget<HeadScene>(find.byType(HeadScene)).zoom, 2);
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<HeadScene>(find.byType(HeadScene)).zoom, 2);
    await capture('head-zoom');
    final List<HeadRegion> before = List<HeadRegion>.of(selected);
    await tester.drag(find.byType(HeadGestureSurface), const Offset(130, 20));
    await tester.pump();
    expect(selected, before);
    await tester.pump(const Duration(milliseconds: 350));
    await capture('head-profile');
    await tester.tap(find.byTooltip('Reset view'));
    await tester.pump();
    // Back to the level that fills THIS viewport, not back to a constant:
    // Reset forgets the user's zoom and the picker measures the box again.
    expect(
      tester.widget<HeadScene>(find.byType(HeadScene)).zoom,
      closeTo(HeadViewportUtils.fitZoom(bounds, surfaceRect.size), 0.001),
    );
    await tester.tap(find.text('Back').first);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 350));
    await capture('head-back');

    resizePicker(() => pickerHeight = 500);
    await tester.pump();
    for (final double yaw in <double>[90, 270]) {
      tester.widget<HeadScene>(find.byType(HeadScene)).onPoseChanged!((
        yaw: yaw,
        pitch: 0,
        zoom: 2,
      ));
      await tester.pump();
      final Rect expanded = tester.getRect(find.byType(HeadGestureSurface));
      final SceneView view = tester.widget<SceneView>(find.byType(SceneView));
      final double oldHalfWidth =
          expanded.height * HeadRegionGeometry.aspectRatio / 2;
      Offset? edgePoint;
      HeadRegion? edgeRegion;

      expect(
        expanded.width,
        tester.getSize(find.byType(HeadRegionPicker)).width,
      );
      for (double y = 4; y < expanded.height && edgePoint == null; y += 4) {
        for (double x = 4; x < expanded.width; x += 4) {
          if ((x - expanded.width / 2).abs() <= oldHalfWidth + 4) continue;
          final Offset point = Offset(x, y);
          final SceneRaycastHit? hit = view.scene!.raycast(
            view.camera!.screenPointToRay(point, expanded.size),
          );
          final HeadRegion? region = HeadModelContract.regionOf(hit?.node.name);
          if (region == null) continue;
          edgePoint = point;
          edgeRegion = region;
          break;
        }
      }
      expect(
        edgePoint,
        isNotNull,
        reason: 'Profile extends beyond the old clip.',
      );
      final bool wasSelected = selected.contains(edgeRegion);
      await tester.tapAt(expanded.topLeft + edgePoint!);
      await tester.pump();
      expect(selected.contains(edgeRegion), !wasSelected);
      await capture('head-full-width-${yaw.toInt()}');
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('two read-only scenes isolate pose and selection materials', (
    WidgetTester tester,
  ) async {
    final Node template = (await HeadSceneStore.load())!;
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: <Widget>[
            Expanded(
              child: HeadScene(
                template: template,
                selected: const <HeadRegion>[HeadRegion.templeL],
                yaw: 0,
              ),
            ),
            Expanded(
              child: HeadScene(
                template: template,
                selected: const <HeadRegion>[],
                yaw: 180,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final List<SceneView> views = tester
        .widgetList<SceneView>(find.byType(SceneView))
        .toList();
    final Node left = HeadModelContract.nodes(
      views[0].scene!.root,
    ).firstWhere((Node n) => n.name == 'region_templeL');
    final Node right = HeadModelContract.nodes(
      views[1].scene!.root,
    ).firstWhere((Node n) => n.name == 'region_templeL');
    final PhysicallyBasedMaterial first =
        left.mesh!.primitives.first.material as PhysicallyBasedMaterial;
    final PhysicallyBasedMaterial second =
        right.mesh!.primitives.first.material as PhysicallyBasedMaterial;
    expect(identical(first, second), isFalse);
    expect(first.baseColorFactor, isNot(second.baseColorFactor));
    for (final HeadGestureSurface surface
        in tester.widgetList<HeadGestureSurface>(
          find.byType(HeadGestureSurface),
        )) {
      expect(surface.onTap, isNull);
      expect(surface.onChanged, isNull);
    }
    final Node duplicate = template.clone();
    duplicate.add(
      HeadModelContract.nodes(
        duplicate,
      ).firstWhere((Node n) => n.name == 'region_templeL').clone(),
    );
    expect(() => HeadModelContract.validate(duplicate), throwsFormatException);
    final Node unbounded = template.clone()
      ..add(Node(name: 'empty-decoration'));
    expect(() => HeadModelContract.validate(unbounded), throwsFormatException);
    expect(tester.takeException(), isNull);
  });
}
