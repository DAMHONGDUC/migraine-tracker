import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/premium/presentation/widgets/premium_settings_tile.dart';

import '../../helpers/pump_app.dart';

/// The Premium row is the signed-in user's view of their subscription. The
/// screen behind it reports status; buying still happens on the paywall.
void main() {
  testWidgets('signed in and free: the row opens the premium screen', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
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

  testWidgets('signed out: Settings has no premium row', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.byType(PremiumSettingsTile), findsNothing);
    await finishTest(tester);
  });
}
