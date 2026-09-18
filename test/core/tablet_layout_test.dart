import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_log_button.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:migraine_tracker/features/settings/presentation/screens/settings_screen/settings_screen.dart';
import 'package:system_design/index.dart';

import '../helpers/pump_app.dart';
import 'screen_overflow_test.dart' show expectNoOverflow, seedHistory;

/// The two rules that make the app a tablet app, asserted at a tablet size.
///
/// Both are no-ops on a phone by design, so the default `pumpApp` size proves
/// nothing about either — these are the only tests that pump anything wider.
void main() {
  /// iPad 11", the device App Review runs the app on.
  const Size portrait = Size(820, 1180);
  const Size landscape = Size(1180, 820);

  group('the scale ceiling', () {
    testWidgets('a tablet renders ~1.15x the design, not 2.1x', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      // Handed the design straight, screenutil would scale this by 820/393 =
      // 2.09 and paint the app's 16 gutter at 33.
      expect(
        SdSpacingConstant.w16,
        closeTo(16 * SdScreenScale.maxScale, 0.5),
        reason: 'the horizontal scale escaped its ceiling',
      );
      expect(
        SdSpacingConstant.h16,
        closeTo(16 * SdScreenScale.maxScale, 0.5),
        reason: 'the vertical scale escaped its ceiling',
      );

      await finishTest(tester);
    });

    testWidgets('a phone is untouched by the ceiling', (tester) async {
      await pumpApp(tester);

      // 393 wide IS the design, so nothing scales and nothing may.
      expect(SdSpacingConstant.w16, closeTo(16, 0.01));

      await finishTest(tester);
    });
  });

  group('the three gaps', () {
    // Owner's rule: screen edge -> rail, rail -> content, content -> far edge
    // are one number, the same in either orientation.
    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('are equal and fixed in $name', (tester) async {
        await pumpApp(tester, surfaceSize: size);

        final Rect rail = tester.getRect(
          find.byKey(SdNavigationRailV2.railSurfaceKey),
        );
        // The card, not the column box: the box carries the screen's own
        // gutter inside it, and the gap the eye sees is to the card edge.
        final Rect card = tester.getRect(find.byType(DashboardLogButton));

        final double edgeToRail = rail.left;
        final double railToCard = card.left - rail.right;
        final double cardToEdge = size.width - card.right;
        final double expected = SdContentPaddingV2.tabletMargin;

        expect(edgeToRail, closeTo(expected, 0.5), reason: 'edge -> rail');
        expect(railToCard, closeTo(expected, 0.5), reason: 'rail -> content');
        expect(cardToEdge, closeTo(expected, 0.5), reason: 'content -> edge');

        await finishTest(tester);
      });
    }

    testWidgets('a phone keeps its own gutter and adds nothing', (
      tester,
    ) async {
      await pumpApp(tester);

      final BuildContext context = tester.element(find.byType(DashboardScreen));

      expect(SdContentPaddingV2.pageMargin(context), 0);
      expect(
        tester.getRect(find.byType(DashboardLogButton)).left,
        closeTo(SdContentPaddingV2.horizontal, 0.5),
      );

      await finishTest(tester);
    });

    // Owner's rule: a screen with no shell nav draws the SAME width, centred.
    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('a pushed screen is the same width, centred, in $name', (
        tester,
      ) async {
        final PumpedApp app = await pumpApp(tester, surfaceSize: size);
        await seedHistory(app);

        final double tabCard = tester
            .getSize(find.byType(DashboardLogButton))
            .width;

        // The attack detail is a sibling of the shell route, so it opens with
        // no rail beside it at all.
        await openHistory(tester);
        await tester.tap(find.byType(AttackTile).first);
        await settleFrames(tester);

        expect(find.byType(SdNavigationRailV2), findsNothing);

        final Rect pushed = tester.getRect(find.byType(ListView).first);
        final double pushedCard =
            pushed.width - SdContentPaddingV2.horizontal * 2;

        expect(
          pushedCard,
          closeTo(tabCard, 0.5),
          reason: 'the content jumped width on the way into a detail screen',
        );
        expect(
          size.width - pushed.right,
          closeTo(pushed.left, 0.5),
          reason: 'a screen with no rail must be centred',
        );

        await finishTest(tester);
      });
    }

    testWidgets('the app bar shares the content margin', (tester) async {
      await pumpApp(tester, surfaceSize: landscape);

      final Rect bar = tester.getRect(find.byType(SdAppBarV2));
      final Rect body = tester.getRect(find.byType(ListView).first);

      expect(
        bar.left,
        closeTo(body.left, 0.5),
        reason: 'the app bar and the body disagreed on where the screen starts',
      );
      expect(bar.right, closeTo(body.right, 0.5));

      await finishTest(tester);
    });
  });

  group('the shell chrome', () {
    testWidgets('a phone keeps the bottom pill', (tester) async {
      await pumpApp(tester);

      expect(find.byType(SdBottomNavigationV2), findsOne);
      expect(find.byType(SdNavigationRailV2), findsNothing);

      await finishTest(tester);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('a tablet in $name puts the tabs down the side', (
        tester,
      ) async {
        await pumpApp(tester, surfaceSize: size);

        expect(find.byType(SdNavigationRailV2), findsOne);
        expect(find.byType(SdBottomNavigationV2), findsNothing);

        // Leading edge, and the body starts after it.
        final Rect rail = tester.getRect(find.byType(SdNavigationRailV2));
        final Rect column = tester.getRect(find.byType(ListView).first);

        expect(rail.left, closeTo(0, 0.5));
        expect(
          column.left,
          greaterThanOrEqualTo(SdContentPaddingV2.floatingRailWidth - 0.5),
          reason: 'the content column started underneath the rail',
        );

        await finishTest(tester);
      });
    }

    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('the rail is longer than it is thick in $name', (
        tester,
      ) async {
        await pumpApp(tester, surfaceSize: size);

        final Size rail = tester.getSize(
          find.byKey(SdNavigationRailV2.railSurfaceKey),
        );

        // Thickness comes off the WIDTH ladder, not the height: screenutil
        // scales the two axes by different amounts, and a thickness taken
        // vertically came out 54 in landscape against 64 in portrait — one
        // control, two thicknesses, depending on how the iPad was held. This
        // assertion is the same number in both runs of the loop.
        expect(
          rail.width,
          closeTo(SdContentPaddingV2.floatingRailThickness, 0.5),
        );
        expect(
          rail.height,
          closeTo(SdContentPaddingV2.floatingRailCellHeight * 5, 0.5),
          reason: 'five destinations, one cell each',
        );
        expect(rail.height, greaterThan(rail.width * 4));

        await finishTest(tester);
      });
    }

    testWidgets('all five tabs still switch from the rail', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      // Settings is the last destination — reaching it proves the rail's
      // segments are hit-testable down their whole length.
      await tester.tap(find.byIcon(AppIconConstant.settings));
      await settleFrames(tester);

      expect(find.byType(SettingsScreen), findsOne);

      await finishTest(tester);
    });

    testWidgets('a tablet stops reserving the pill height', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      // `floatingNav: true` means "I am a tab screen", and with the rail up
      // there is nothing on the bottom edge to clear — the tab screens must
      // fall back to the plain detail inset.
      final BuildContext context = tester.element(find.byType(DashboardScreen));

      expect(
        SdContentPaddingV2.bottom(context, floatingNav: true),
        closeTo(SdContentPaddingV2.detailBottom(context), 0.5),
      );

      await finishTest(tester);
    });

    testWidgets('a phone still reserves it', (tester) async {
      await pumpApp(tester);

      final BuildContext context = tester.element(find.byType(DashboardScreen));

      expect(
        SdContentPaddingV2.bottom(context, floatingNav: true),
        greaterThan(SdContentPaddingV2.detailBottom(context)),
      );

      await finishTest(tester);
    });
  });

  // The same question `screen_overflow_test.dart` asks at 393, asked at the
  // two sizes the caps actually engage at. Landscape is the harder of the two:
  // it is the only window in the app that is wider than it is tall.
  group('nothing overflows at tablet sizes', () {
    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('the tab screens fit in $name', (tester) async {
        final PumpedApp app = await pumpApp(tester, surfaceSize: size);
        await seedHistory(app);

        await expectNoOverflow(tester, 'Dashboard ($name)');

        await openHistory(tester);
        await expectNoOverflow(tester, 'History list ($name)');

        await openHistoryCharts(tester);
        await expectNoOverflow(tester, 'History charts ($name)');

        await openInsights(tester);
        await expectNoOverflow(tester, 'Insights ($name)');

        await openSettings(tester);
        await expectNoOverflow(tester, 'Settings ($name)');

        await finishTest(tester);
      });

      testWidgets('the log flow fits in $name', (tester) async {
        await pumpApp(tester, surfaceSize: size);

        await openLog(tester);
        await expectNoOverflow(tester, 'Log flow ($name)');

        await finishTest(tester);
      });
    }
  });
}
