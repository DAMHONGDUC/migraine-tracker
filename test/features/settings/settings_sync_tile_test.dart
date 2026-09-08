import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Hard rule 12 reversed the manual control: sync is entirely automatic, and
  // `SyncScreen`, the `/sync` route and the eight `syncScreen*` / `settingsSync*`
  // ARB keys are deleted. This file used to assert the row into existence; it
  // asserts its absence now, because a row is what would come back first.
  for (final (String state, bool signedIn) in <(String, bool)>[
    ('signed out', false),
    ('signed in', true),
  ]) {
    testWidgets('$state, Settings offers no sync control at all', (
      tester,
    ) async {
      await pumpApp(tester, signedIn: signedIn);
      await openSettings(tester);

      // Both halves of hard rule 12: nothing to tap, and nothing reporting on
      // it either — an indicator is a control the user cannot use.
      expect(find.text('Sync data to cloud'), findsNothing);
      expect(find.text('Last synced'), findsNothing);

      // The row that IS there, so a section emptied by mistake fails here
      // rather than passing as "no sync row found".
      await scrollIntoView(tester, find.text('Export data'));
      expect(find.text('Export data'), findsOneWidget);

      await finishTest(tester);
    });
  }
}
