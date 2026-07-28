import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/app_content_padding.dart';
import 'package:migraine_tracker/core/widgets/app_scaffold.dart';
import 'package:migraine_tracker/core/widgets/glass/liquid_glass_theme.dart';

/// The app's one spacing rule, pinned on a notched device: [topGap] below
/// the bar, [bottomGap] above the home indicator, [horizontal] either side.
/// The numbers are spelled out rather than read back from the class — a test
/// that computes the same expression it is testing proves nothing.
void main() {
  /// Pumps [builder] on a 393×852 view (so screenutil scales 1:1) with a
  /// 47pt status bar and a 34pt home indicator.
  Future<EdgeInsets> insetsOf(
    WidgetTester tester,
    EdgeInsets Function(BuildContext context) read,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);

    late final EdgeInsets insets;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              insets = read(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return insets;
  }

  setUp(() => AppGlass.debugSupported = true);
  tearDown(() => AppGlass.debugSupported = null);

  testWidgets(
    'content clears the app bar by topGap and the inset by bottomGap',
    (tester) async {
      final EdgeInsets insets = await insetsOf(
        tester,
        (BuildContext context) => AppContentPadding.screen(context),
      );

      // 47 status bar + 56 toolbar + topGap.
      expect(insets.top, 47 + kToolbarHeight + 8);
      // 34 home indicator + bottomGap.
      expect(insets.bottom, 34 + 8);
      expect(insets.left, 16);
      expect(insets.right, 16);
    },
  );

  testWidgets('a tab screen also clears the floating nav pill', (tester) async {
    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) =>
          AppContentPadding.screen(context, floatingNav: true),
    );

    // 34 home indicator + 68 pill + 8 hover gap + bottomGap.
    expect(insets.bottom, 34 + 68 + 8 + 8);
    // The pill changes nothing above it.
    expect(insets.top, 47 + kToolbarHeight + 8);
  });

  testWidgets('full-bleed keeps the vertical rule, drops the gutter', (
    tester,
  ) async {
    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) => AppContentPadding.fullBleed(context),
    );

    expect(insets.top, 47 + kToolbarHeight + 8);
    expect(insets.bottom, 34 + 8);
    expect(insets.left, 0);
    expect(insets.right, 0);
  });

  testWidgets('appBarInset survives Scaffold stripping the top padding', (
    tester,
  ) async {
    AppGlass.debugSupported = true;
    addTearDown(() => AppGlass.debugSupported = null);
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    // A notched device: 47pt of status bar (141 physical / DPR 3).
    tester.view.padding = const FakeViewPadding(top: 141);
    tester.view.viewPadding = const FakeViewPadding(top: 141);
    addTearDown(tester.view.reset);

    late final double above;
    late final double below;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext outer) {
            above = AppContentPadding.appBarInset(outer);
            return AppScaffold(
              title: const Text('Title'),
              body: Builder(
                builder: (BuildContext inner) {
                  // Scaffold strips the body's top padding when there is an
                  // app bar; the inset must survive that (AppActionView is
                  // the body, so this is where it gets read).
                  below = AppContentPadding.appBarInset(inner);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(above, 47 + kToolbarHeight);
    expect(below, above);
  });

  testWidgets('without glass the bar is opaque, so no top inset', (
    tester,
  ) async {
    AppGlass.debugSupported = false;

    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) => AppContentPadding.screen(context),
    );

    // The body already starts below the bar; only the gap is left.
    expect(insets.top, 8);
    expect(insets.bottom, 34 + 8);
  });
}
