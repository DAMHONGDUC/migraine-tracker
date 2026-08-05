import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/premium_gate.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

/// 15 attacks with weather — enough for the correlation engine to produce a
/// real insight (9 during rapid drops → 60%).
Future<void> seedInsightData(WidgetTester tester, PumpedApp app) async {
  final repo = DriftAttackRepository(app.db);
  for (var i = 0; i < 15; i++) {
    final startedAt = DateTime.now().toUtc().subtract(Duration(days: i));
    await repo.insert(
      Attack(
        id: 'seed-$i',
        startedAt: startedAt,
        intensity: 5,
        location: HeadLocation.left,
        weather: WeatherSnapshot(
          capturedAt: startedAt,
          pressureHpa: 1010,
          pressureDelta24hHpa: i < 9 ? -7 : 2,
        ),
      ),
    );
  }
}

PressureForecast forecast() => PressureForecast(
  generatedAt: DateTime.now().toUtc(),
  points: [
    for (var h = -12; h <= 48; h++)
      PressurePoint(
        time: DateTime.now().toUtc().add(Duration(hours: h)),
        pressureHpa: 1010 - h * 0.1,
      ),
  ],
);

void main() {
  testWidgets('the dev toggle unlocks every gate, and locking re-locks them', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedInsightData(tester, app);
    await openInsights(tester);

    // Signed out and with no entitlement, the analysis is teased.
    expect(find.text('60%'), findsNothing);

    // Driven through the row a developer actually taps. The override has to
    // reach the gates, not just the switch that owns it — that is the whole
    // point of layering it inside hasPremiumProvider.
    await openSettings(tester);
    await tapVisible(tester, find.text('Premium (mock)'));

    await openInsights(tester);
    expect(find.text('60%'), findsOneWidget);

    await openSettings(tester);
    await tapVisible(tester, find.text('Premium (mock)'));

    await openInsights(tester);
    expect(find.text('60%'), findsNothing);

    await finishTest(tester);
  });

  group('free user', () {
    testWidgets('never sees the correlation percentage, only the teaser', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);

      await openInsights(tester);

      // The analysis output is absent from the tree entirely.
      expect(find.text('60%'), findsNothing);
      expect(find.textContaining('Based on'), findsNothing);
      // The value moment is teased instead.
      expect(
        find.text('Unlock to see how much of your pain follows the weather.'),
        findsOneWidget,
      );
      expect(find.text('Premium'), findsWidgets);

      await finishTest(tester);
    });

    testWidgets('never sees the forecast chart', (tester) async {
      final app = await pumpApp(tester);
      app.weather.forecast = forecast();

      await openInsights(tester);

      expect(find.byType(LineChart), findsNothing);
      expect(
        find.text(
          'See the pressure forecast 48 hours ahead, so you can plan around it.',
        ),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('cannot reach the alerts toggle or the PDF report', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      // Locked rows in place of the real controls: the alerts row is a name
      // wearing the badge, never the toggle. SwitchListTile, not Switch — the
      // dev-only premium mock is a Switch too, and this is asking about the
      // gated toggles, not about every switch on the screen.
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.text('Pressure-drop alerts'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsWidgets);

      // The PDF report now lives behind the export screen's picker, still
      // locked: the row is a pitch, never a path that produces a report.
      await tapVisible(tester, find.text('Export data'));
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Export'));
      expect(
        find.text('Export a PDF summary of your attacks for your doctor.'),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('still gets logging, history and the export (free forever)', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);

      await openSettings(tester);
      expect(find.text('Export data'), findsOneWidget);

      await openMedications(tester);
      expect(find.text('Medications'), findsOneWidget);

      // Logging works — reachable from the dashboard's hero button.
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await openLog(tester);
      expect(find.text('How intense is the pain?'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('tapping Unlock opens the paywall, account or not', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);
      await openInsights(tester);

      await tester.tap(find.text('Unlock').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The pitch comes first: a login screen must never appear in front of
      // a paywall the user has not been shown yet.
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(find.text('Sign in to unlock Premium'), findsNothing);
      // …and the CTA is the account, since there is none yet.
      expect(find.text('Sign in to continue'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('the paywall CTA leads to login, and comes back unlockable', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);
      await openInsights(tester);

      await tester.tap(find.text('Unlock').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tapVisible(tester, find.text('Sign in to continue'));
      expect(find.text('Sign in to unlock Premium'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Back on the paywall it was opened from, now offering the purchase.
      expect(app.auth.signInCalls, [AuthProviderKind.google]);
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('backing out of login leaves the paywall standing', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);
      await openInsights(tester);

      await tester.tap(find.text('Unlock').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tapVisible(tester, find.text('Sign in to continue'));
      await tapVisible(tester, find.text('Not now'));

      expect(app.auth.signInCalls, isEmpty);
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('an entitlement without an account unlocks nothing', (
      tester,
    ) async {
      // The combination RevenueCat can produce on a fresh install: a
      // restored entitlement with nobody signed in.
      final app = await pumpApp(tester, premium: true, signedIn: false);
      await seedInsightData(tester, app);

      await openInsights(tester);

      expect(find.text('60%'), findsNothing);
      expect(find.text('Premium'), findsWidgets);

      await finishTest(tester);
    });

    testWidgets(
      'below the data threshold it sees progress, not a paywall tease',
      (tester) async {
        await pumpApp(tester); // no attacks
        await openInsights(tester);

        // The correlation card shows the "keep logging" progress, not a
        // paywall tease — the tease only appears once there's enough data.
        // (The forecast card above it is separately gated, so "Unlock" can
        // still appear from there — this asserts the correlation branch.)
        expect(
          find.text(
            'Log 15 more attacks with weather data to unlock this insight.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Unlock to see how much of your pain follows the weather.'),
          findsNothing,
        );

        await finishTest(tester);
      },
    );
  });

  group('premium user', () {
    testWidgets('sees the correlation percentage', (tester) async {
      final app = await pumpApp(tester, premium: true);
      await seedInsightData(tester, app);

      await openInsights(tester);

      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('sees the forecast chart', (tester) async {
      final app = await pumpApp(tester, premium: true);
      app.weather.forecast = forecast();

      await openInsights(tester);

      expect(find.byType(LineChart), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('gets the alerts toggle and the PDF report', (tester) async {
      await pumpApp(tester, premium: true);
      await openSettings(tester);

      // The toggle lives on the alerts detail screen now, not on Settings —
      // the row here only reports On/Off. Unlocked means the row opens it.
      expect(find.byType(SwitchListTile), findsNothing);
      await tapVisible(tester, find.text('Pressure-drop alerts'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SwitchListTile), findsOneWidget);

      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 400));

      // No locked teaser left anywhere on the screen. (The Premium row is
      // titled 'Premium' now, so the badge is what marks a gate.)
      expect(find.byType(PremiumBadge), findsNothing);

      // The report is offered for real in the export picker — no badge, no
      // pitch, just the row that produces it.
      await tapVisible(tester, find.text('Export data'));
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Export'));

      expect(find.text('Doctor report (PDF)'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsNothing);

      await finishTest(tester);
    });
  });
}
