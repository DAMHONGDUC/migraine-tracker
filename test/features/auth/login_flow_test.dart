import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_error.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Future<void> openLogin(WidgetTester tester) async {
  await openSettings(tester);
  await tester.tap(find.text('Sign in'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('signed out', () {
    testWidgets('Settings offers sign-in and opens the login screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Sign in to unlock Premium'), findsOneWidget);
      // Hard rule 1: the sign-in UI states what happens to health data — and
      // now that sync ships, that it leaves the device at all.
      expect(
        find.text(
          'Signing in backs up your attacks to your account, encrypted. They '
          'stay on this device too, and stay yours to delete at any time.',
        ),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('shows both providers, in the shape the app has to ship in', (
      tester,
    ) async {
      await pumpApp(tester);
      await openLogin(tester);

      // App Store 4.8: offering Google obliges us to offer Apple too. The
      // button is on screen from the start, even before its flow is wired.
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      await finishTest(tester);
    });

    // The kill-switch state, not the shipped one: `appleSignIn: false` is
    // what the Firebase/portal side breaking would look like.
    testWidgets('tapping Apple says it is not wired up, and does not try', (
      tester,
    ) async {
      final app = await pumpApp(tester, appleSignIn: false);
      await openLogin(tester);

      await tapVisible(tester, find.text('Sign in with Apple'));

      expect(
        find.text(
          'Sign in with Apple is coming soon. Please use Google for now.',
        ),
        findsOneWidget,
      );
      // Never reaches the provider — no half-started flow to recover from.
      expect(app.auth.signInCalls, isEmpty);
      expect(find.text('Sign in to unlock Premium'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('scrolls instead of overflowing on a short viewport', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openLogin(tester);

      // Well short of what the pitch plus buttons need. A fixed Column here
      // would throw a RenderFlex overflow, which this test would fail on.
      tester.view.physicalSize = const Size(393 * 3, 480 * 3);
      await tester.pump();

      // And the CTA is still reachable, just further down.
      await tapVisible(tester, find.text('Continue with Google'));
      expect(app.auth.signInCalls, [AuthProviderKind.google]);

      await finishTest(tester);
    });

    testWidgets('hides the Apple button where the platform cannot serve it', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      // Read when LoginScreen builds, which has not happened yet.
      app.auth.appleAvailable = false;

      await openLogin(tester);

      expect(find.text('Sign in with Apple'), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('signing in returns to Settings showing the account', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openLogin(tester);

      await tapVisible(tester, find.text('Continue with Google'));

      expect(app.auth.signInCalls, [AuthProviderKind.google]);
      // Settings shows the account row (which opens the account screen),
      // never the email itself.
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('tester@example.com'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('the Apple path runs, as shipped', (tester) async {
      final app = await pumpApp(tester);
      await openLogin(tester);

      await tapVisible(tester, find.text('Sign in with Apple'));

      expect(app.auth.signInCalls, [AuthProviderKind.apple]);
      expect(find.text('Account'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('a failed sign-in reports why and stays put', (tester) async {
      final app = await pumpApp(tester);
      app.auth.failWith = AuthError.network;

      await openLogin(tester);

      await tapVisible(tester, find.text('Continue with Google'));

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('Sign in to unlock Premium'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('cancelling is not reported as a failure', (tester) async {
      final app = await pumpApp(tester);
      app.auth.failWith = AuthError.cancelled;

      await openLogin(tester);

      await tapVisible(tester, find.text('Continue with Google'));

      expect(find.byType(SdSnackBarCardV2), findsNothing);
      expect(find.text('Sign in to unlock Premium'), findsOneWidget);

      await finishTest(tester);
    });
  });

  group('signed in', () {
    testWidgets('Settings shows the account instead of a sign-in row', (
      tester,
    ) async {
      await pumpApp(tester, signedIn: true);
      await openSettings(tester);

      // The row says 'Account' and opens the account screen; Settings
      // never puts the email on screen.
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('tester@example.com'), findsNothing);
      expect(find.text('Sign in'), findsNothing);

      await finishTest(tester);
    });
  });
}
