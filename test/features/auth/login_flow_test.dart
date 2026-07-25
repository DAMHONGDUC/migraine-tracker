import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_error.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';

import '../../helpers/pump_app.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

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

      expect(find.text('Optional — needed to unlock Premium'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Sign in to unlock Premium'), findsOneWidget);
      // Hard rule 1: the sign-in UI states what happens to health data.
      expect(
        find.text(
          'Your attacks stay on this device. Signing in never uploads your '
          'health data.',
        ),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('offers Apple as well as Google where the platform can', (
      tester,
    ) async {
      await pumpApp(tester);
      await openLogin(tester);

      // App Store 4.8: offering Google obliges us to offer Apple too.
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

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

      await tapVisible(tester, find.text('Sign in with Apple'));

      expect(app.auth.signInCalls, [AuthProviderKind.apple]);
      expect(find.text('tester@example.com'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

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

      expect(find.byType(SnackBar), findsNothing);
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

      expect(find.text('tester@example.com'), findsOneWidget);
      expect(find.text('Optional — needed to unlock Premium'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('signing out is confirmed first, then reverts the row', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedIn: true);
      await openSettings(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The confirm explains that nothing on-device is lost (hard rule 1).
      expect(
        find.text(
          'Your attacks stay on this device. Premium features lock until you '
          'sign in again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(app.auth.signOutCalls, 0);

      await tester.tap(find.text('Sign out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // 'Sign out' now matches both the row and the dialog's confirm.
      await tester.tap(find.text('Sign out').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(app.auth.signOutCalls, 1);
      expect(find.text('Optional — needed to unlock Premium'), findsOneWidget);

      await finishTest(tester);
    });
  });
}
