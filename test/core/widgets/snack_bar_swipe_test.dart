import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/index.dart';

/// A snackbar leaves on a swipe back towards the edge it came from — up for a
/// top card, down for a bottom one — and stays put for a drag the other way.
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

    await tester.drag(find.byType(SdSnackBarCardV2), by);
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
