import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/index.dart';

/// A snackbar leaves on a swipe back towards the edge it came from — up for a
/// top card, down for a bottom one — or on a swipe sideways either way, and
/// stays put for the one drag that has nowhere to go.
void main() {
  /// Shows a snackbar at [placement], drags the card by [by], and answers
  /// whether it is still on screen once everything has settled.
  Future<bool> survivesDrag(
    WidgetTester tester, {
    required SdSnackBarPlacementV2 placement,
    required Offset by,
  }) async {
    late final BuildContext screen;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                screen = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    SdSnackBarUtilsV2.info(screen, 'saved', placement: placement);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // `dragFrom`, not `drag`: the card itself is an `IgnorePointer` so taps
    // fall through to the screen under it, and only the detector around it
    // takes the gesture — which is a miss as far as `drag`'s finder is
    // concerned, however well the drag then works.
    await tester.dragFrom(tester.getCenter(find.byType(SdSnackBarCardV2)), by);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final bool alive = find.byType(SdSnackBarCardV2).evaluate().isNotEmpty;

    // Let a surviving card leave on its own; a live timer outlives the test.
    if (alive) {
      await tester.pump(SdSnackBarUtilsV2.duration);
      await tester.pump(const Duration(milliseconds: 300));
    }

    return alive;
  }

  testWidgets('a top card leaves when swiped up', (WidgetTester tester) async {
    expect(
      await survivesDrag(
        tester,
        placement: SdSnackBarPlacementV2.top,
        by: const Offset(0, -60),
      ),
      isFalse,
    );
  });

  testWidgets('a bottom card leaves when swiped down', (
    WidgetTester tester,
  ) async {
    expect(
      await survivesDrag(
        tester,
        placement: SdSnackBarPlacementV2.bottom,
        by: const Offset(0, 60),
      ),
      isFalse,
    );
  });

  testWidgets('a bottom card leaves when swiped right', (
    WidgetTester tester,
  ) async {
    expect(
      await survivesDrag(
        tester,
        placement: SdSnackBarPlacementV2.bottom,
        by: const Offset(80, 0),
      ),
      isFalse,
    );
  });

  testWidgets('a top card leaves when swiped left', (
    WidgetTester tester,
  ) async {
    expect(
      await survivesDrag(
        tester,
        placement: SdSnackBarPlacementV2.top,
        by: const Offset(-80, 0),
      ),
      isFalse,
    );
  });

  testWidgets('a tap where the card sits still reaches what is under it', (
    WidgetTester tester,
  ) async {
    late final BuildContext screen;
    int taps = 0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                screen = context;

                // The bottom of the screen, which is where the card lands.
                return GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(
                    color: Colors.transparent,
                    child: SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    SdSnackBarUtilsV2.info(screen, 'saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // `tapAt`, not `tap`: the card deliberately does not hit-test, which is
    // the whole point — a message never costs the button it is sitting on.
    await tester.tapAt(tester.getCenter(find.byType(SdSnackBarCardV2)));
    await tester.pump();

    expect(taps, 1);

    await tester.pump(SdSnackBarUtilsV2.duration);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('a drag away from its own edge keeps the card', (
    WidgetTester tester,
  ) async {
    expect(
      await survivesDrag(
        tester,
        placement: SdSnackBarPlacementV2.bottom,
        by: const Offset(0, -60),
      ),
      isTrue,
    );
  });
}
