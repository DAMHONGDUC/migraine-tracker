import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Onboarding runs before anything else exists, so what matters here is that a first-launch user can get through every page, and that the sheet telling.
void main() {
  /// Onboarding's buttons sit in a fixed bar at the bottom, always on screen, so they are tapped directly.
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

    await finishTest(tester);
  });

  testWidgets(
    'the feature sheet names every feature and badges the paid ones',
    (tester) async {
      await pumpApp(
        tester,
        initialPrefs: <String, Object>{'onboarding_completed': false},
      );
      await nextPage(tester);
      await nextPage(tester);

      // The list is behind a button on the last step, not a page of its own.
      expect(find.text('Three-tap attack log'), findsNothing);
      await tapButton(tester, 'See all app features');

      // Free — none of these wears a badge. The wipe is here and stays here: hard rule 8 makes deleting your own records a promise, not an offer.
      expect(find.text('Three-tap attack log'), findsOneWidget);
      expect(find.text('History and charts'), findsOneWidget);
      expect(find.text('Medication reminders'), findsOneWidget);
      expect(find.text('Delete everything'), findsOneWidget);

      // Premium — one badge each, and the group heading is the eighth. Export moved over here whole: the file is premium, the wipe is not.
      expect(find.text('Export your data'), findsOneWidget);
      expect(find.text('Pressure-drop alerts'), findsOneWidget);
      expect(find.text('7-day pressure forecast'), findsOneWidget);
      expect(find.text('Weather correlation'), findsOneWidget);
      expect(find.text('Exertion and steps'), findsOneWidget);
      expect(find.text('Sleep correlation'), findsOneWidget);
      expect(find.text('Doctor report'), findsOneWidget);
      expect(find.text('Premium'), findsNWidgets(8));

      await finishTest(tester);
    },
  );

  testWidgets('every page is reachable in order, ending on the threshold', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      initialPrefs: <String, Object>{'onboarding_completed': false},
    );

    await nextPage(tester);
    expect(find.text('Why location?'), findsOneWidget);

    // One button, reading "Continue", and it always raises the OS prompt.
    expect(find.text('Not now'), findsNothing);
    expect(find.text('Enable location'), findsNothing);
    expect(app.location.requestCalls, 0);

    await nextPage(tester);
    expect(app.location.requestCalls, 1);
    expect(find.text('When should we warn you?'), findsOneWidget);
    expect(find.text('Start tracking'), findsOneWidget);

    await finishTest(tester);
  });
}
