import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
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

  group('the content column', () {
    testWidgets('stops at contentMaxWidth on a tablet', (tester) async {
      await pumpApp(tester, surfaceSize: landscape);

      // The screen still fills the window; its scrollable is what is capped.
      expect(
        tester.getSize(find.byType(DashboardScreen)).width,
        closeTo(landscape.width, 0.5),
      );
      expect(
        tester.getSize(find.byType(ListView).first).width,
        lessThanOrEqualTo(SdBreakpointV2.contentMaxWidth + 0.5),
        reason: 'the body column ran the full width of a landscape iPad',
      );

      await finishTest(tester);
    });

    testWidgets('is the whole window on a phone', (tester) async {
      await pumpApp(tester);

      expect(
        tester.getSize(find.byType(ListView).first).width,
        closeTo(393, 0.5),
        reason: 'the cap engaged on a phone, where it must do nothing',
      );

      await finishTest(tester);
    });
  });

  group('nothing overflows at tablet sizes', () {
    for (final (String name, Size size) in <(String, Size)>[
      ('portrait', portrait),
      ('landscape', landscape),
    ]) {
      testWidgets('the dashboard fits in $name', (tester) async {
        final PumpedApp app = await pumpApp(tester, surfaceSize: size);
        await seedHistory(app);

        await expectNoOverflow(tester, 'Dashboard ($name)');

        await finishTest(tester);
      });
    }
  });
}
