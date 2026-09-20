import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_log_button.dart';
import 'package:migraine_tracker/features/history/presentation/screens/history_screen/history_screen.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:migraine_tracker/features/insights/presentation/screens/insights_screen/insights_screen.dart';
import 'package:migraine_tracker/features/medications/presentation/screens/medications_screen/medications_screen.dart';
import 'package:migraine_tracker/features/settings/presentation/screens/settings_screen/settings_screen.dart';
import 'package:system_design/index.dart';

import '../helpers/pump_app.dart';
import 'screen_overflow_test.dart' show expectNoOverflow, seedHistory;

/// The three rules that make the app a tablet app, asserted at a tablet size.
///
/// All of them are no-ops on a phone by design, so the default `pumpApp` size
/// proves nothing about any of them — these are the only tests that pump
/// anything wider, and the assertions that pump 393 are what prove the phone
/// build did not move.
void main() {
  /// iPad 11", the device App Review runs the app on.
  const Size portrait = Size(820, 1180);
  const Size landscape = Size(1180, 820);

  /// The narrowest window that gets the panel at all — the breakpoint itself.
  const Size narrowest = Size(600, 900);

  const List<(String, Size)> tabletSizes = <(String, Size)>[
    ('portrait', portrait),
    ('landscape', landscape),
  ];

  Finder toggle() => find.byKey(SdNavPanelToggleV2.toggleKey);

  Finder panelRegion() => find.byKey(SdNavPanelV2.panelRegionKey);

  Finder contentRegion() => find.byKey(SdNavPanelV2.contentRegionKey);

  /// The panel's full width, read off the tree the test just pumped.
  double fullPanelWidth(WidgetTester tester) => SdContentPaddingV2.navPanelWidth(
    tester.element(find.byType(DashboardScreen)),
  );

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

  group('the two regions', () {
    // A fifth and four fifths, whatever the window: the panel is proportional
    // because a fixed width is either too wide in portrait or too narrow in
    // landscape.
    for (final (String name, Size size) in <(String, Size)>[
      ('the breakpoint itself', narrowest),
      ...tabletSizes,
    ]) {
      testWidgets('the panel takes a fifth at $name', (tester) async {
        await pumpApp(tester, surfaceSize: size);

        expect(
          tester.getSize(panelRegion()).width,
          closeTo(size.width / 5, 0.5),
        );
        expect(
          tester.getSize(contentRegion()).width,
          closeTo(size.width * 4 / 5, 0.5),
        );

        await finishTest(tester);
      });
    }

    for (final (String name, Size size) in tabletSizes) {
      testWidgets('collapsed, the panel draws nothing at all in $name', (
        tester,
      ) async {
        await pumpApp(tester, surfaceSize: size);

        await tester.tap(toggle());
        await settleFrames(tester);

        expect(tester.getSize(panelRegion()).width, 0);
        expect(
          find.byKey(SdNavPanelV2.panelSurfaceKey),
          findsNothing,
          reason: 'a collapsed panel must not leave a rail or a strip behind',
        );
        expect(
          tester.getSize(contentRegion()).width,
          closeTo(size.width, 0.5),
          reason: 'the content must start where it would with no panel at all',
        );

        await finishTest(tester);
      });

      testWidgets('the content keeps equal gutters in $name', (tester) async {
        await pumpApp(tester, surfaceSize: size);

        // The card, not the column box: the box carries the screen's own
        // gutter inside it, and the gap the eye sees is to the card edge.
        Rect card = tester.getRect(find.byType(DashboardLogButton));
        Rect region = tester.getRect(contentRegion());

        expect(
          card.left - region.left,
          closeTo(SdContentPaddingV2.horizontal, 0.5),
          reason: 'expanded: panel -> card',
        );
        expect(
          region.right - card.right,
          closeTo(SdContentPaddingV2.horizontal, 0.5),
          reason: 'expanded: card -> edge',
        );

        await tester.tap(toggle());
        await settleFrames(tester);

        card = tester.getRect(find.byType(DashboardLogButton));
        region = tester.getRect(contentRegion());

        expect(
          card.left - region.left,
          closeTo(SdContentPaddingV2.horizontal, 0.5),
          reason: 'collapsed: edge -> card',
        );
        expect(
          region.right - card.right,
          closeTo(SdContentPaddingV2.horizontal, 0.5),
          reason: 'collapsed: card -> edge',
        );

        await finishTest(tester);
      });
    }

    testWidgets('the content column is wider than a phone\'s', (tester) async {
      await pumpApp(tester);

      final double phone = tester.getSize(find.byType(DashboardLogButton)).width;

      await finishTest(tester);

      for (final (String name, Size size) in tabletSizes) {
        await pumpApp(tester, surfaceSize: size);

        expect(
          tester.getSize(find.byType(DashboardLogButton)).width,
          greaterThan(phone),
          reason: 'the panel took its room out of the content in $name',
        );

        await finishTest(tester);
      }
    });

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
    for (final (String name, Size size) in tabletSizes) {
      testWidgets('a pushed screen is the same width, centred, in $name', (
        tester,
      ) async {
        final PumpedApp app = await pumpApp(tester, surfaceSize: size);
        await seedHistory(app);

        final double tabCard = tester
            .getSize(find.byType(DashboardLogButton))
            .width;

        // The attack detail is a sibling of the shell route, so it opens with
        // no panel beside it at all.
        await openHistory(tester);
        await tester.tap(find.byType(AttackTile).first);
        await settleFrames(tester);

        expect(find.byType(SdNavPanelV2), findsNothing);

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
          reason: 'a screen with no panel must be centred',
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

  group('the reopen control', () {
    testWidgets('expanded, it is in the panel and not in the app bar', (
      tester,
    ) async {
      await pumpApp(tester, surfaceSize: portrait);

      expect(
        find.descendant(
          of: find.byKey(SdNavPanelV2.panelSurfaceKey),
          matching: toggle(),
        ),
        findsOne,
      );
      expect(
        find.descendant(of: find.byType(SdAppBarV2), matching: toggle()),
        findsNothing,
        reason: 'the panel holds its own close control while it is open',
      );

      await finishTest(tester);
    });

    testWidgets('collapsed, it moves into the app bar', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      await tester.tap(toggle());
      await settleFrames(tester);

      expect(
        find.descendant(of: find.byType(SdAppBarV2), matching: toggle()),
        findsOne,
        reason: 'a collapsed panel has nowhere of its own to draw the control',
      );

      final BuildContext context = tester.element(find.byType(DashboardScreen));

      // The screen's app bar owns the top safe inset in both states, which is
      // the whole reason the control lives in it rather than in a strip above
      // the content.
      expect(
        tester.getRect(find.byType(SdAppBarV2)).height,
        closeTo(SdContentPaddingV2.appBarInset(context), 0.5),
      );

      await finishTest(tester);
    });

    testWidgets('a screen whose bar swaps its title still hosts it', (
      tester,
    ) async {
      await pumpApp(tester, surfaceSize: portrait);

      await openMedications(tester);
      await tester.tap(toggle());
      await settleFrames(tester);

      expect(find.byType(MedicationsScreen), findsOne);
      expect(
        find.descendant(of: find.byType(SdAppBarV2), matching: toggle()),
        findsOne,
        reason: 'the collapsing filter chrome asks for the control too',
      );

      await finishTest(tester);
    });

    testWidgets('exactly one exists mid-animation, in both directions', (
      tester,
    ) async {
      await pumpApp(tester, surfaceSize: portrait);

      final double full = fullPanelWidth(tester);

      // Halfway out: the panel is still painting and the app bar has already
      // claimed the control, so the key has to be on exactly one of them.
      await tester.tap(toggle());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(toggle(), findsOne);
      expect(tester.getSize(panelRegion()).width, greaterThan(0));
      expect(tester.getSize(panelRegion()).width, lessThan(full));

      // Reversed mid-flight, which is what overflows a panel whose contents
      // reflow as the width travels.
      await tester.tap(toggle());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(toggle(), findsOne);
      expect(tester.getSize(panelRegion()).width, greaterThan(0));
      expect(tester.getSize(panelRegion()).width, lessThan(full));
      expect(tester.takeException(), isNull);

      await settleFrames(tester);

      expect(tester.getSize(panelRegion()).width, closeTo(full, 0.5));
      expect(tester.takeException(), isNull);

      await finishTest(tester);
    });

    testWidgets('reduced motion changes the width on the next frame', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await pumpApp(tester, surfaceSize: portrait);

      await tester.tap(toggle());
      // Two zero-length frames: the first carries the state change, the second
      // is the first frame the width is allowed to move on.
      await tester.pump();
      await tester.pump();

      expect(tester.getSize(panelRegion()).width, 0);

      await finishTest(tester);
    });

    testWidgets('with motion on, the same two frames do not move it', (
      tester,
    ) async {
      await pumpApp(tester, surfaceSize: portrait);

      final double full = fullPanelWidth(tester);

      await tester.tap(toggle());
      await tester.pump();
      await tester.pump();

      expect(
        tester.getSize(panelRegion()).width,
        closeTo(full, 0.5),
        reason: 'no time passed, so the panel cannot have travelled',
      );

      await finishTest(tester);
    });

    testWidgets('the tap target clears the platform minimum', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      // A fixed square around a glyph, so this is the size at every text
      // scale — there is no text in it to grow.
      final Size target = tester.getSize(toggle());

      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));

      await finishTest(tester);
    });

    testWidgets('a phone never has one', (tester) async {
      await pumpApp(tester);

      expect(toggle(), findsNothing);

      await finishTest(tester);
    });
  });

  group('the shell chrome', () {
    testWidgets('a phone keeps the bottom pill', (tester) async {
      await pumpApp(tester);

      expect(find.byType(SdBottomNavigationV2), findsOne);
      expect(find.byType(SdNavPanelV2), findsNothing);

      await finishTest(tester);
    });

    for (final (String name, Size size) in tabletSizes) {
      testWidgets('a tablet in $name puts the tabs down the side', (
        tester,
      ) async {
        await pumpApp(tester, surfaceSize: size);

        expect(find.byType(SdNavPanelV2), findsOne);
        expect(find.byType(SdBottomNavigationV2), findsNothing);

        // Leading edge, full height, and the content starts where it ends —
        // the two surfaces meet with no gap between them.
        final Rect panel = tester.getRect(panelRegion());
        final Rect content = tester.getRect(contentRegion());

        expect(panel.left, closeTo(0, 0.5));
        expect(panel.height, closeTo(size.height, 0.5));
        expect(content.left, closeTo(panel.right, 0.5));

        await finishTest(tester);
      });
    }

    testWidgets('every destination still switches, by semantics label', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await pumpApp(tester, surfaceSize: portrait);

      // The panel paints the label and the cell is the one node carrying it, so
      // every destination is reached the way a screen reader reaches it — the
      // whole list, in order, so a dead row cannot hide behind a live one.
      const List<(String, Type)> destinations = <(String, Type)>[
        ('History', HistoryScreen),
        ('Medications', MedicationsScreen),
        ('Insights', InsightsScreen),
        ('Settings', SettingsScreen),
        ('Home', DashboardScreen),
      ];

      for (final (String label, Type screen) in destinations) {
        tester.semantics.tap(
          find.semantics.byPredicate(
            (SemanticsNode node) =>
                node.label == label &&
                node.getSemanticsData().flagsCollection.isButton,
            describeMatch: (_) => 'the $label destination',
          ),
        );
        await settleFrames(tester);

        expect(find.byType(screen), findsOne, reason: '$label did not switch');
      }

      // Before `finishTest`, which is the last frame: a live handle at the end
      // of a test is a failure of its own.
      semantics.dispose();
      await finishTest(tester);
    });

    testWidgets('a tablet stops reserving the pill height', (tester) async {
      await pumpApp(tester, surfaceSize: portrait);

      // `floatingNav: true` means "I am a tab screen", and with the panel down
      // the side there is nothing on the bottom edge to clear — the tab screens
      // must fall back to the plain detail inset.
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
  // two sizes the panel engages at. Landscape is the harder of the two: it is
  // the only window in the app that is wider than it is tall.
  group('nothing overflows at tablet sizes', () {
    for (final (String name, Size size) in tabletSizes) {
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

      testWidgets('the tab screens fit with the panel collapsed in $name', (
        tester,
      ) async {
        final PumpedApp app = await pumpApp(tester, surfaceSize: size);
        await seedHistory(app);

        await tester.tap(toggle());
        await settleFrames(tester);

        await expectNoOverflow(tester, 'Dashboard, collapsed ($name)');

        await openHistory(tester);
        await expectNoOverflow(tester, 'History list, collapsed ($name)');

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
