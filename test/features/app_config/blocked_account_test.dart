import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config_grants.dart';

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
    // The row is keyed on the address, so a session that carries none matches
    // nothing — even with a blocked row sitting in the collection.
    await pumpApp(
      tester,
      appConfigGrants: const AppConfigGrants(blocked: true),
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
      appConfigGrants: const AppConfigGrants(blocked: true),
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
      appConfigGrants: const AppConfigGrants(blocked: true),
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
      appConfigGrants: const AppConfigGrants(blocked: true),
    );

    expect(find.text('Account locked'), findsOneWidget);

    app.appConfig.emitGrants(AppConfigGrants.none);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Account locked'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);

    await finishTest(tester);
  });
}
