import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/premium/domain/enums/purchase_error.dart';
import 'package:migraine_tracker/features/premium/presentation/screens/paywall_screen/paywall_screen.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';
import 'premium_gating_test.dart' show seedInsightData;

/// The paywall's own CTA. Its label ("Unlock") is the same one the Insights
/// gate card behind it carries, and that card stays mounted under the pushed
/// route — so the finder has to be scoped to the paywall.
Finder paywallCta() => find.descendant(
  of: find.byType(PaywallScreen),
  matching: find.text('Unlock'),
);

/// Opens the paywall from the Insights gate — the door every premium
/// surface uses (CLAUDE.md: "the pitch comes first").
Future<void> openPaywall(WidgetTester tester, PumpedApp app) async {
  await seedInsightData(tester, app);
  await openInsights(tester);

  await tester.tap(find.text('Unlock').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Rect of [finder] against the sheet's own bounds.
bool _isFullyInside(WidgetTester tester, Finder finder, Rect bounds) {
  final Rect rect = tester.getRect(finder);

  return rect.top >= bounds.top && rect.bottom <= bounds.bottom;
}

void main() {
  testWidgets('the plans and the CTA are pinned, not scrolled to', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await openPaywall(tester, app);

    // - the pitch scrolls, the thing being sold does not — that's what holds on a small phone or large text size
    // - asserting only "on screen" would pass whenever the pitch happens to be short — how this regressed unnoticed before
    final Finder scroller = find.descendant(
      of: find.byType(PaywallScreen),
      matching: find.byType(SingleChildScrollView),
    );

    for (final String label in <String>['Monthly', 'Yearly', 'Lifetime']) {
      expect(
        find.descendant(of: scroller, matching: find.text(label)),
        findsNothing,
        reason: '$label is inside the scroll view — it can fall below the fold',
      );
    }
    expect(
      find.descendant(of: scroller, matching: paywallCta()),
      findsNothing,
      reason: 'the buy button is inside the scroll view',
    );

    // And they really do land on screen as laid out.
    final Rect sheet = tester.getRect(find.byType(PaywallScreen));

    expect(_isFullyInside(tester, find.text('Yearly'), sheet), isTrue);
    expect(_isFullyInside(tester, paywallCta(), sheet), isTrue);
    expect(
      _isFullyInside(tester, find.text('Restore purchases'), sheet),
      isTrue,
    );

    await finishTest(tester);
  });

  testWidgets('a signed-out paywall sells before it asks for an account', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await openPaywall(tester, app);

    // No prices behind a sign-in wall: tapping one could not complete.
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text(r'$29.99'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
    expect(app.purchases.purchased, isEmpty);

    await finishTest(tester);
  });

  testWidgets('a signed-in paywall lists the plans at store prices', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await openPaywall(tester, app);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.text(r'$29.99'), findsOneWidget);
    expect(find.text(r'$44.99'), findsOneWidget);
    // The trial belongs to the package, not to copy in the app.
    expect(find.text('7-day free trial'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the CTA buys the yearly plan by default', (tester) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await openPaywall(tester, app);

    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.purchases.purchased, <String>[r'$rc_annual']);
    // Entitlement came from the stream, not from the paywall deciding.
    expect(app.premiumRepository.isPremium, isTrue);

    await finishTest(tester);
  });

  testWidgets('picking a plan changes what the CTA buys', (tester) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await openPaywall(tester, app);

    await tapVisible(tester, find.text('Lifetime'));
    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.purchases.purchased, <String>[r'$rc_lifetime']);

    await finishTest(tester);
  });

  testWidgets('a cancelled purchase is silent and changes nothing', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.purchases.failWith = const PurchaseException(PurchaseError.cancelled);
    await openPaywall(tester, app);

    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    // Closing Apple's sheet is a decision, not an error to report.
    expect(find.textContaining("didn't go through"), findsNothing);
    expect(app.premiumRepository.isPremium, isFalse);

    await finishTest(tester);
  });

  testWidgets('a store failure says so and leaves the user free', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.purchases.failWith = const PurchaseException(PurchaseError.network);
    await openPaywall(tester, app);

    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining("Couldn't reach the store"), findsOneWidget);
    expect(app.premiumRepository.isPremium, isFalse);

    await finishTest(tester);
  });

  testWidgets('a paywall message is drawn above the sheet, not under it', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.purchases.failWith = const PurchaseException(PurchaseError.network);
    await openPaywall(tester, app);

    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    final Finder card = find.byType(SdSnackBarCardV2);

    expect(card, findsOneWidget);
    // - in the root overlay, not the route: a ScaffoldMessenger drew into the Scaffold underneath, so the sheet covered it
    // - text a test can find is not text a user can see
    expect(
      find.descendant(of: find.byType(PaywallScreen), matching: card),
      findsNothing,
      reason: 'the message is inside the paywall route — it can be covered',
    );
    // - anchored to the top edge, above where the sheet begins
    // - may still overlap the sheet lower down (drawn over it, being in the overlay), but must not start at the bottom, on the plans
    expect(
      tester.getRect(card).top,
      lessThan(
        tester
            .getRect(
              find.descendant(
                of: find.byType(PaywallScreen),
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .top,
      ),
      reason: 'the message hangs off the bottom edge, where the sheet is',
    );

    await finishTest(tester);
  });

  testWidgets('restore with nothing to restore says exactly that', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await openPaywall(tester, app);

    await tapVisible(tester, find.text('Restore purchases'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.purchases.restoreCalls, 1);
    expect(find.text('Nothing to restore on this account.'), findsOneWidget);
    expect(app.premiumRepository.isPremium, isFalse);

    await finishTest(tester);
  });

  testWidgets('restore brings a previous purchase back', (tester) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.purchases.hasPastPurchase = true;
    await openPaywall(tester, app);

    await tapVisible(tester, find.text('Restore purchases'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.premiumRepository.isPremium, isTrue);

    await finishTest(tester);
  });

  testWidgets('an empty offering disables the CTA rather than failing on tap', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.purchases.availableOffers = const [];
    await openPaywall(tester, app);

    expect(find.textContaining('No plans are available'), findsOneWidget);

    await tapVisible(tester, paywallCta());
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.purchases.purchased, isEmpty);

    await finishTest(tester);
  });

  testWidgets('purchases are bound to the account on a signed-in launch', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);

    // An entitlement has to follow the person, not the install.
    expect(app.purchases.identified, contains('test-uid'));

    await finishTest(tester);
  });
}
