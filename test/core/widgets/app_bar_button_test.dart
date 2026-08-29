import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:system_design/index.dart';

/// Verifies the app-bar glyph remains easy to hit during a migraine.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
    SdAppBarButtonSurfaceV2 surface = SdAppBarButtonSurfaceV2.glassCircle,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SdAppBarButtonV2(
                icon: AppIconConstant.delete,
                tooltip: 'Delete',
                surface: surface,
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The pop is a paint-time transform, so the icon's *layout* size never changes — the animation value is the only honest reading of it.
  double scaleOf(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(SdPopScaleV2),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('the glyph is small and the target is not', (tester) async {
    await pumpButton(tester, onPressed: () {});

    expect(
      tester.getSize(find.byIcon(AppIconConstant.delete)).width,
      SdAppBarButtonV2.iconSize,
    );
    expect(
      tester.getSize(find.byType(SdAppBarButtonV2)).width,
      SdAppBarButtonV2.tapSize,
    );
    // The whole square is the target, so it dwarfs the mark drawn in it.
    expect(SdAppBarButtonV2.tapSize, greaterThan(SdAppBarButtonV2.iconSize * 2));
  });

  testWidgets('a tap in the corner of the square still counts', (tester) async {
    int taps = 0;

    await pumpButton(tester, onPressed: () => taps++);

    // Well clear of the glyph, inside the invisible square.
    final Rect box = tester.getRect(find.byType(SdAppBarButtonV2));
    await tester.tapAt(box.topLeft + const Offset(2, 2));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('touching it swells the glyph, then settles back', (
    tester,
  ) async {
    await pumpButton(tester, onPressed: () {});

    expect(scaleOf(tester), 1);

    // Hold the finger down: the swell runs on the pointer-down, so it does not wait to learn whether this is a tap or a long press.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SdPopScaleV2)),
    );
    // One empty pump first: the ticker starts on the frame after the touch, so a single timed pump would still read the resting value.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(scaleOf(tester), greaterThan(1));

    // ...and it settles back on its own, still held down.
    await tester.pump(const Duration(milliseconds: 400));
    expect(scaleOf(tester), 1);

    await gesture.up();
    await tester.pump();
  });

  // - the whole button swells, surface included - get this backwards (circle wrapped around the pop, not inside it) and the glyph grows inside a static circle
  testWidgets('the swell wraps the surface, not the other way round', (
    tester,
  ) async {
    await pumpButton(tester, onPressed: () {});

    expect(
      find.ancestor(
        of: find.byType(SdGlassCircleV2),
        matching: find.byType(SdPopScaleV2),
      ),
      findsOneWidget,
    );
  });

  testWidgets('on a glass surface it drops the circle', (tester) async {
    await pumpButton(
      tester,
      onPressed: () {},
      surface: SdAppBarButtonSurfaceV2.none,
    );

    expect(find.byType(SdGlassCircleV2), findsNothing);
    expect(find.byType(SdPopScaleV2), findsOneWidget);
  });

  testWidgets('disabled, it does not pop', (tester) async {
    await pumpButton(tester);

    expect(find.byType(SdPopScaleV2), findsNothing);
  });
}
