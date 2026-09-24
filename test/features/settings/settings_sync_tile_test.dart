import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  // The sync card at the top of Settings (owner's rule, 2026-09-24): it shows
  // what sync is doing, and it is still no control — sync stays automatic, and
  // `SyncScreen`, `/sync` and the old manual row stay deleted.
  testWidgets('signed out, Settings has no sync card', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.text('All saved'), findsNothing);
    expect(find.text('Syncing'), findsNothing);

    await finishTest(tester);
  });

  testWidgets(
    'signed in, the card sits above every group and says it is saved',
    (tester) async {
      await pumpApp(tester, signedIn: true);
      await openSettings(tester);
      await tester.pump(const Duration(seconds: 1));

      final Finder card = find.text('All saved');

      expect(card, findsOneWidget);
      expect(
        tester.getRect(card).top,
        lessThan(tester.getRect(find.text('General')).top),
      );
      // Still nothing to tap: the old manual row is what would come back first.
      expect(find.text('Sync data to cloud'), findsNothing);

      await finishTest(tester);
    },
  );
}
