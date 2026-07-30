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
      expect(insets.bottom, 34 + 16);
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

    // The pill rests on the 34 home indicator, so: that + its 56 of height +
    // bottomGap.
    expect(insets.bottom, 34 + 56 + 16);
    // The pill changes nothing above it.
    expect(insets.top, 47 + kToolbarHeight + 8);
  });

  testWidgets('with no home indicator the pill takes a flat 16 instead', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    // A Home-button phone: status bar, no gesture bar at the bottom.
    tester.view.padding = const FakeViewPadding(top: 60);
    tester.view.viewPadding = const FakeViewPadding(top: 60);
    addTearDown(tester.view.reset);

    late final double bottom;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext _, Widget? _) => MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              bottom = AppContentPadding.bottom(context, floatingNav: true);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // Nothing to rest on, so the pill floats 16 off the edge: that + its 56 +
    // bottomGap.
    expect(bottom, 16 + 56 + 16);
  });

  testWidgets('full-bleed keeps the vertical rule, drops the gutter', (
    tester,
  ) async {
    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) => AppContentPadding.fullBleed(context),
    );

    expect(insets.top, 47 + kToolbarHeight + 8);
    expect(insets.bottom, 34 + 16);
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
    expect(insets.bottom, 34 + 16);
  });

  testWidgets('the bar inset survives Scaffold stripping the bottom padding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);

    late final double tabScreen;
    late final double logFlow;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext _, Widget? _) => MaterialApp(
          // The shape both floating bars come in: a bottom bar, and a body
          // that reaches under it.
          home: Scaffold(
            extendBody: true,
            bottomNavigationBar: const SizedBox(height: 56),
            body: Builder(
              builder: (BuildContext context) {
                // Scaffold subtracts padding.bottom from the body's
                // viewPadding.bottom whenever there is a bottom bar, so an
                // ambient read here loses the home indicator entirely — and
                // the last row ends up under the bar.
                tabScreen = AppContentPadding.bottom(
                  context,
                  floatingNav: true,
                );
                logFlow = AppContentPadding.bottomBar(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    // Both bars rest on the 34 home indicator here, so both come to the same
    // sum — what matters is that neither lost it.
    expect(tabScreen, 34 + 56 + 16);
    expect(logFlow, 34 + 56 + 16);
  });
}
