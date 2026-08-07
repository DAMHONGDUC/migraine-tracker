import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/index.dart';

/// A bottom snackbar draws into the root overlay, above everything — so on a
/// tab screen it has to be told the nav pill is down there, or it lands on it.
void main() {
  setUp(() => SdGlassV2.debugSupported = true);
  tearDown(() => SdGlassV2.debugSupported = null);

  /// Shows a snackbar on a 393×852 view with a 34pt home indicator, and
  /// returns how far its card sits above the bottom edge.
  Future<double> gapAboveBottom(
    WidgetTester tester, {
    required bool withFloatingBar,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(bottom: 102);
    addTearDown(tester.view.reset);

    late final BuildContext screen;
    final Widget body = Builder(
      builder: (BuildContext context) {
        screen = context;
        return const SizedBox.expand();
      },
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: withFloatingBar
                ? SdFloatingBarScopeV2(child: body)
                : body,
          ),
        ),
      ),
    );

    SdSnackBarUtilsV2.info(screen, 'saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final double gap =
        852 - tester.getRect(find.byType(SdSnackBarCardV2)).bottom;

    // Let it leave on its own; a live timer outlives the test otherwise.
    await tester.pump(SdSnackBarUtilsV2.duration);
    await tester.pump(const Duration(milliseconds: 300));
    return gap;
  }

  testWidgets('without a floating bar it rests on the home indicator', (
    tester,
  ) async {
    expect(await gapAboveBottom(tester, withFloatingBar: false), 34 + 16);
  });

  testWidgets('with one it clears the whole bar instead', (tester) async {
    // navBarOffset (34 clamped to 20) + floatingBarHeight (56), then the gap.
    expect(await gapAboveBottom(tester, withFloatingBar: true), 20 + 56 + 16);
  });
}
