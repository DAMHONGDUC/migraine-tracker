import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('About screen shows the joined env/version/build string', (
    tester,
  ) async {
    await pumpApp(tester);

    await openSettings(tester);

    // The Settings row is a title and nothing else now — the diagnostic string moved onto the screen behind it, where the About header prints it beside "Version". Asserting it on the row asks Settings for a value it stopped carrying.
    await tapVisible(tester, find.text('About BaroEase'));
    await tester.pump(const Duration(milliseconds: 400));

    // Still one tap from Settings, so a bug report can still name its build.
    expect(find.text('dev - 99.0.0 (9999)'), findsOneWidget);

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
    expect(app.mailLauncher.body, contains('dev - 99.0.0 (9999)'));

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
