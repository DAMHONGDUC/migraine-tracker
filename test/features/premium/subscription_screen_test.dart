import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/sections/premium_settings_tile.dart';

import '../../helpers/pump_app.dart';

/// The Premium row is the user's view of their subscription — everyone's, account or not.
void main() {
  testWidgets('free: the row opens the premium screen', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.byType(PremiumSettingsTile), findsOneWidget);
    await tapVisible(tester, find.byType(PremiumSettingsTile));
    await tester.pump(const Duration(milliseconds: 300));

    // The screen lists BOTH halves of the offer now, not just what Premium adds.
    expect(find.text('Free forever'), findsOneWidget);
    expect(find.text('Free plan'), findsWidgets);
    expect(find.text('Unlock'), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('a subscriber sees the status, not an unlock button', (
    tester,
  ) async {
    await pumpApp(tester, premium: true);
    await openSettings(tester);
    await tapVisible(tester, find.byType(PremiumSettingsTile));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Premium is active'), findsWidgets);
    expect(find.text('Unlock'), findsNothing);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(
      find.textContaining('Manage or cancel your subscription'),
      findsOneWidget,
    );
    await finishTest(tester);
  });

  testWidgets('nothing for the store to manage hides the button, not the note', (
    tester,
  ) async {
    // An account premium by the app_access allow-list has no purchase behind it, so the store hands back no page — and a button onto nothing reads as broken.
    final PumpedApp app = await pumpApp(tester, premium: true);

    app.purchases.management = null;

    await openSettings(tester);
    await tapVisible(tester, find.byType(PremiumSettingsTile));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Manage subscription'), findsNothing);
    expect(
      find.textContaining('Manage or cancel your subscription'),
      findsOneWidget,
    );
    await finishTest(tester);
  });

  testWidgets('signed out: Settings still has the premium row', (tester) async {
    // It used to be hidden without an account.
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.byType(PremiumSettingsTile), findsOneWidget);
    await finishTest(tester);
  });
}
