import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/sections/premium_settings_tile.dart';
import 'package:migraine_tracker/features/auth/domain/entities/user_profile.dart';

import '../../helpers/pump_app.dart';

/// The account screen is reached from Settings and only exists with an
/// account; it shows account data and nothing about attacks (hard rule 1).
void main() {
  Future<void> openAccount(WidgetTester tester) async {
    await openSettings(tester);
    await tapVisible(tester, find.text('Account'));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('signed out: Settings offers sign-in, not an account', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.text('Sign in'), findsOneWidget);
    // The premium row needs no account (App Store 5.1.1(v)) and sits next to
    // the sign-in one. 'Premium' the word also appears on the locked gates,
    // so this asks for the row itself.
    expect(find.byType(PremiumSettingsTile), findsOneWidget);
    await finishTest(tester);
  });

  testWidgets('signed in: the account row opens the account screen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      userProfile: const UserProfile(
        uid: 'test-uid',
        displayName: 'Duc',
        email: 'tester@example.com',
      ),
    );
    await openAccount(tester);

    // The app bar title, plus the Settings row underneath it.
    expect(find.text('Account'), findsWidgets);
    expect(find.text('Duc'), findsWidgets);
    expect(find.text('tester@example.com'), findsWidgets);
    await finishTest(tester);
  });

  testWidgets('the account document is pushed on a signed-in launch', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);

    expect(app.profiles.synced.single.uid, 'test-uid');
    await finishTest(tester);
  });

  testWidgets('an anonymous session pushes nothing', (tester) async {
    final PumpedApp app = await pumpApp(tester);

    expect(app.profiles.synced, isEmpty);
    await finishTest(tester);
  });

  testWidgets('editing the name saves it to the account document', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      userProfile: const UserProfile(
        uid: 'test-uid',
        displayName: 'Duc',
        email: 'tester@example.com',
      ),
    );
    await openAccount(tester);

    await tapVisible(tester, find.byIcon(Icons.edit_outlined));
    await tester.enterText(find.byType(TextField), 'Hong Duc');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(app.profiles.renames, <String>['Hong Duc']);
    expect(find.text('Hong Duc'), findsWidgets);
    await finishTest(tester);
  });

  testWidgets('signing out is confirmed first, and cancel keeps the account', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      userProfile: const UserProfile(
        uid: 'test-uid',
        email: 'tester@example.com',
      ),
    );
    await openAccount(tester);

    await tapVisible(tester, find.text('Sign out'));
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
    expect(find.text('Account'), findsWidgets);
    await finishTest(tester);
  });

  testWidgets('signing out returns to Settings', (tester) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      userProfile: const UserProfile(
        uid: 'test-uid',
        email: 'tester@example.com',
      ),
    );
    await openAccount(tester);

    await tapVisible(tester, find.text('Sign out'));
    await tester.pump(const Duration(milliseconds: 300));
    // The dialog's confirm, over the button that opened it.
    await tester.tap(find.text('Sign out').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.auth.signOutCalls, 1);
    expect(find.text('Sign in'), findsOneWidget);
    await finishTest(tester);
  });
}
