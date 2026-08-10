import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('About section shows the joined env/version/build string', (
    tester,
  ) async {
    await pumpApp(tester);

    await openSettings(tester);
    await tester.dragUntilVisible(
      find.text('About BaroEase'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );

    // The version row is gone: the About row carries the same diagnostic
    // string as its value, so a bug report still names its build.
    expect(find.text('About BaroEase'), findsOneWidget);
    expect(find.text('dev - 99.0.0 - 9999'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('Contact support opens the mail app addressed to support', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await openSettings(tester);
    await tapVisible(tester, find.text('Contact support'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('support@baroease.app'), findsOneWidget);

    await tapVisible(tester, find.text('Email support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(app.mailLauncher.to, 'support@baroease.app');
    expect(app.mailLauncher.subject, 'BaroEase support');
    expect(app.mailLauncher.body, contains('dev - 99.0.0 - 9999'));

    await finishTest(tester);
  });

  testWidgets('a failed mail launch shows an error snackbar', (tester) async {
    final app = await pumpApp(tester);
    app.mailLauncher.succeeds = false;

    await openSettings(tester);
    await tapVisible(tester, find.text('Contact support'));
    await tester.pump(const Duration(milliseconds: 400));

    await tapVisible(tester, find.text('Email support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Couldn't open your mail app."), findsOneWidget);

    await finishTest(tester);
  });
}
