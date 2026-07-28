import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/app_bar_button.dart';
import 'package:migraine_tracker/core/widgets/pop_scale.dart';

/// The one app-bar button: a small glyph inside a touch target big enough to
/// hit while a migraine builds, and feedback that swells out from under the
/// fingertip instead of hiding beneath it.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
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
              child: AppBarButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The pop is a paint-time transform, so the icon's *layout* size never
  /// changes — the animation value is the only honest reading of it.
  double scaleOf(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(PopScale),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('the glyph is small and the target is not', (tester) async {
    await pumpButton(tester, onPressed: () {});

    expect(
      tester.getSize(find.byIcon(Icons.delete_outline)).width,
      AppBarButton.iconSize,
    );
    expect(
      tester.getSize(find.byType(AppBarButton)).width,
      AppBarButton.tapSize,
    );
    // The whole square is the target, so it dwarfs the mark drawn in it.
    expect(AppBarButton.tapSize, greaterThan(AppBarButton.iconSize * 2));
  });

  testWidgets('a tap in the corner of the square still counts', (tester) async {
    int taps = 0;

    await pumpButton(tester, onPressed: () => taps++);

    // Well clear of the glyph, inside the invisible square.
    final Rect box = tester.getRect(find.byType(AppBarButton));
    await tester.tapAt(box.topLeft + const Offset(2, 2));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('touching it swells the glyph, then settles back', (
    tester,
  ) async {
    await pumpButton(tester, onPressed: () {});

    expect(scaleOf(tester), 1);

    // Hold the finger down: the swell runs on the pointer-down, so it does
    // not wait to learn whether this is a tap or a long press.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(PopScale)),
    );
    // One empty pump first: the ticker starts on the frame after the touch,
    // so a single timed pump would still read the resting value.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(scaleOf(tester), greaterThan(1));

    // ...and it settles back on its own, still held down.
    await tester.pump(const Duration(milliseconds: 400));
    expect(scaleOf(tester), 1);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('disabled, it does not pop', (tester) async {
    await pumpButton(tester);

    expect(find.byType(PopScale), findsNothing);
  });
}
