import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the sync row is absent without an account', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    // There is nowhere to sync to, so offering it would be a dead end.
    expect(find.text('Sync data to cloud'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('signed in, the row sits in "Your data" and leads to the screen', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await openSettings(tester);

    await tester.dragUntilVisible(
      find.text('Sync data to cloud'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );

    // Alongside export and delete: sync is one more thing that happens to the user's data, not a section of its own.
    expect(find.text('Export data'), findsOneWidget);

    await tapVisible(tester, find.text('Sync data to cloud'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The row is a plain chevron row now; everything about sync lives here.
    expect(find.text('Last synced'), findsOneWidget);

    await finishTest(tester);
  });
}
