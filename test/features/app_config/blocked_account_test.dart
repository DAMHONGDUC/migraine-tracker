import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';

import '../../helpers/pump_app.dart';

/// The gate replaces the whole app, so these guard the case that matters most: it must NOT appear for anybody the row does not name.
void main() {
  testWidgets('an address the row does not name reaches the app', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);

    expect(find.text('Account locked'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an anonymous session is never blocked', (tester) async {
    // Membership is by address, so a session that carries none matches
    // nothing — even with the list naming somebody.
    await pumpApp(
      tester,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('a blocked address gets the screen instead of the app', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsOneWidget);
    // Not a sheet over the app: the app underneath is gone.
    expect(find.text('Log an attack'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('Sign out is what clears the block', (tester) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    await tapVisible(tester, find.text('Sign out'));

    expect(app.auth.signOutCalls, 1);

    await finishTest(tester);
  });

  testWidgets('unblocking the row puts the app back without a restart', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsOneWidget);

    app.appConfig.emit(AppConfig.empty);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Account locked'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);

    await finishTest(tester);
  });
}
