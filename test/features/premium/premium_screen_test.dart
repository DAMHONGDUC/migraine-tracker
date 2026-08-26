import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/sections/premium_settings_tile.dart';

import '../../helpers/pump_app.dart';

/// The Premium row is the user's view of their subscription — everyone's,
/// account or not. The screen behind it reports status; buying still happens
/// on the paywall.
void main() {
  testWidgets('free: the row opens the premium screen', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.byType(PremiumSettingsTile), findsOneWidget);
    await tapVisible(tester, find.byType(PremiumSettingsTile));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('What premium includes'), findsOneWidget);
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
    expect(
      find.textContaining('Manage or cancel your subscription'),
      findsOneWidget,
    );
    await finishTest(tester);
  });

  testWidgets('signed out: Settings still has the premium row', (tester) async {
    // It used to be hidden without an account. App Store 5.1.1(v): premium
    // is not account-based content, so neither the purchase nor the row
    // reporting it may wait on registration.
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.byType(PremiumSettingsTile), findsOneWidget);
    await finishTest(tester);
  });
}
