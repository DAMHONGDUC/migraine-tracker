import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:system_design/index.dart';

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
          theme: AppTheme.dark,
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

  setUp(() => SdGlassV2.debugSupported = true);
  tearDown(() => SdGlassV2.debugSupported = null);

  testWidgets(
    'content clears the app bar by topGap and the inset by bottomGap',
    (tester) async {
      final EdgeInsets insets = await insetsOf(
        tester,
        (BuildContext context) => SdContentPaddingV2.screen(context),
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
          SdContentPaddingV2.screen(context, floatingNav: true),
    );

    // The 34 home indicator is deeper than the pill's ceiling, so the offset
    // caps at 20: that + its 56 of height + bottomGap.
    expect(insets.bottom, 20 + 56 + 16);
    // The pill changes nothing above it.
    expect(insets.top, 47 + kToolbarHeight + 8);
  });

  testWidgets('with no home indicator the pill falls back to the floor', (
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
          theme: AppTheme.dark,
          home: Builder(
            builder: (BuildContext context) {
              bottom = SdContentPaddingV2.bottom(context, floatingNav: true);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // Nothing to rest on, so the pill takes the floor: that + its 56 +
    // bottomGap.
    expect(bottom, 16 + 56 + 16);
  });

  testWidgets('a bottom inset below the floor is raised to it', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    // An iPad, or an iPhone in landscape: there IS a home indicator, but a
    // shallower one than a portrait phone's 34 — 8, under the floor.
    tester.view.padding = const FakeViewPadding(top: 60, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 60, bottom: 24);
    addTearDown(tester.view.reset);

    late final double bottom;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext _, Widget? _) => MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (BuildContext context) {
              bottom = SdContentPaddingV2.bottom(context, floatingNav: true);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // 8 of real inset, but the pill still clears the edge by the floor.
    expect(bottom, 16 + 56 + 16);
  });

  testWidgets('full-bleed keeps the vertical rule, drops the gutter', (
    tester,
  ) async {
    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) => SdContentPaddingV2.fullBleed(context),
    );

    expect(insets.top, 47 + kToolbarHeight + 8);
    expect(insets.bottom, 34 + 16);
    expect(insets.left, 0);
    expect(insets.right, 0);
  });

  testWidgets('appBarInset survives Scaffold stripping the top padding', (
    tester,
  ) async {
    SdGlassV2.debugSupported = true;
    addTearDown(() => SdGlassV2.debugSupported = null);
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
        theme: AppTheme.dark,
        home: Builder(
          builder: (BuildContext outer) {
            above = SdContentPaddingV2.appBarInset(outer);
            return SdScaffoldV2(
              title: const Text('Title'),
              body: Builder(
                builder: (BuildContext inner) {
                  // Scaffold strips the body's top padding when there is an
                  // app bar; the inset must survive that (SdActionViewV2 is
                  // the body, so this is where it gets read).
                  below = SdContentPaddingV2.appBarInset(inner);
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
    SdGlassV2.debugSupported = false;

    final EdgeInsets insets = await insetsOf(
      tester,
      (BuildContext context) => SdContentPaddingV2.screen(context),
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
                tabScreen = SdContentPaddingV2.bottom(
                  context,
                  floatingNav: true,
                );
                logFlow = SdContentPaddingV2.bottomBar(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    // Neither lost the home indicator, which is what this test is for. They
    // do not agree, and should not: the pill clamps its offset to 20, the log
    // flow's step bar rests on the full 34 whatever that is.
    expect(tabScreen, 20 + 56 + 16);
    expect(logFlow, 34 + 56 + 16);
  });
}
