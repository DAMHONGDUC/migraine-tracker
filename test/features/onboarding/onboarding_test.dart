import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Onboarding runs before anything else exists, so what matters here is that
/// a first-launch user can get through every page, and that the sheet telling
/// them what the app does is honest about which parts they have to pay for.
void main() {
  /// Onboarding's buttons sit in a fixed bar at the bottom, always on screen,
  /// so they are tapped directly — `tapVisible` would try to scroll the
  /// PageView and leave its ballistic simulation running past the test.
  /// Bounded pumps rather than `pumpAndSettle` for the same reason.
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> nextPage(WidgetTester tester) => tapButton(tester, 'Continue');

  testWidgets('a first launch lands on onboarding, not the dashboard', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialPrefs: <String, Object>{'onboarding_completed': false},
    );

    expect(find.text('Track your migraines'), findsOneWidget);
    expect(find.text('Log an attack'), findsNothing);
  });

  testWidgets(
    'the feature sheet names every feature and badges the paid ones',
    (tester) async {
      await pumpApp(
        tester,
        initialPrefs: <String, Object>{'onboarding_completed': false},
      );
      await nextPage(tester);
      await tapButton(tester, 'Not now');

      // The list is behind a button on the last step, not a page of its own.
      expect(find.text('Three-tap attack log'), findsNothing);
      await tapButton(tester, 'See all app features');

      // Free — none of these wears a badge.
      expect(find.text('Three-tap attack log'), findsOneWidget);
      expect(find.text('History and charts'), findsOneWidget);
      expect(find.text('Medication reminders'), findsOneWidget);
      expect(find.text('Export your data'), findsOneWidget);

      // Premium — one badge each, and the group heading is the sixth.
      expect(find.text('Pressure-drop alerts'), findsOneWidget);
      expect(find.text('48-hour pressure forecast'), findsOneWidget);
      expect(find.text('Weather correlation'), findsOneWidget);
      expect(find.text('Sleep correlation'), findsOneWidget);
      expect(find.text('Doctor report'), findsOneWidget);
      expect(find.text('Premium'), findsNWidgets(6));
    },
  );

  testWidgets('every page is reachable in order, ending on the threshold', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialPrefs: <String, Object>{'onboarding_completed': false},
    );

    await nextPage(tester);
    expect(find.text('Why location?'), findsOneWidget);

    // Declining the permission still moves on — the app works without it.
    await tapButton(tester, 'Not now');
    expect(find.text('When should we warn you?'), findsOneWidget);
    expect(find.text('Start tracking'), findsOneWidget);
  });
}
