import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/core/widgets/alert_summary_tag.dart';
import 'package:migraine_tracker/core/widgets/premium_gate.dart';
import 'package:migraine_tracker/core/widgets/sections/alerts_settings_tile.dart';
import 'package:migraine_tracker/core/widgets/sections/premium_settings_tile.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/auth/domain/enums/auth_provider_kind.dart';
import 'package:migraine_tracker/features/insights/presentation/widgets/pressure_card.dart';
import 'package:migraine_tracker/features/insights/presentation/widgets/pressure_history_body.dart';
import 'package:migraine_tracker/features/insights/presentation/widgets/trigger_verdict_body.dart';
import 'package:migraine_tracker/features/weather/domain/entities/pressure_forecast.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

/// The alert row on the pressure card, which is the only locked control on the tab.
Finder alertRowOnCard() => find.descendant(
  of: find.byType(PressureCard),
  matching: find.text('Pressure-drop alerts'),
);

/// Whether the pressure card built the real alert control rather than the locked row.
Finder alertControlOnCard() => find.descendant(
  of: find.byType(PressureCard),
  matching: find.byType(AlertSummaryTag),
);

/// A free user's way onto the paywall from Insights: the locked alert row.
Future<void> openPaywallFromAlertRow(WidgetTester tester) async {
  await openPressureInsight(tester);
  await tapVisible(tester, alertRowOnCard());
  await tester.pump(const Duration(milliseconds: 400));
}

/// 15 attacks with weather — enough for the correlation engine to produce a real insight (9 during rapid drops → 60%).
Future<void> seedInsightData(WidgetTester tester, PumpedApp app) async {
  final repo = DriftAttackRepository(app.db);
  for (var i = 0; i < 15; i++) {
    final startedAt = DateTime.now().toUtc().subtract(Duration(days: i));
    await repo.insert(
      Attack(
        id: 'seed-$i',
        startedAt: startedAt,
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
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
  testWidgets('the dev toggle opens the alert row, and locking closes it', (
    tester,
  ) async {
    // Signed out on purpose: the dev row no longer sits behind an account, because neither does premium (App Store 5.1.1(v)). Unentitled is still not premium.
    await pumpApp(tester);
    await openPressureInsight(tester);
    expect(alertControlOnCard(), findsNothing);

    // Driven through the row a developer actually taps: the override must reach the gates, not just the switch — the whole point of hasPremiumProvider.
    await openSettings(tester);
    await tapVisible(tester, find.text('Premium (mock)'));

    // `openInsights`, not `openPressureInsight`.
    await openInsights(tester);
    expect(alertControlOnCard(), findsOneWidget);

    await openSettings(tester);
    await tapVisible(tester, find.text('Premium (mock)'));

    await openInsights(tester);
    expect(alertControlOnCard(), findsNothing);

    await finishTest(tester);
  });

  // Everything but alerts and export is free (`docs/PREMIUM_RULES.md`).
  group('free user', () {
    testWidgets('sees the correlation, the verdict and the history chart', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);

      await openPressureInsight(tester);

      expect(find.text('60%'), findsOneWidget);
      expect(find.byType(TriggerVerdictBody), findsOneWidget);
      expect(find.byType(PressureHistoryBody), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('sees the forecast chart', (tester) async {
      final app = await pumpApp(tester);
      app.weather.forecast = forecast();

      await openPressureInsight(tester);

      expect(find.byType(LineChart), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('below the data threshold sees progress, not a pitch', (
      tester,
    ) async {
      await pumpApp(tester); // no attacks
      await openPressureInsight(tester);

      expect(
        find.text(
          'Log 15 more attacks with weather data to unlock this insight.',
        ),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('sees every History chart drawn from their own attacks', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);
      await openHistoryCharts(tester);

      expect(find.text('Moderate · 15'), findsOneWidget);
      // One row, the user's own: every seeded attack is `left`.
      expect(find.byType(SdProgressRowV2), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('adds a third reminder, past the limit that used to be', (
      tester,
    ) async {
      await pumpApp(tester);
      await openMedications(tester);
      await addMedication(tester, 'Sumatriptan');
      await openMedication(tester, 'Sumatriptan');

      await addReminders(tester, 3);

      expect(find.byIcon(AppIconConstant.reminder), findsNWidgets(3));
      expect(find.textContaining('on the free plan'), findsNothing);
      expect(find.text('BaroEase Premium'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('the alert row is the one locked control on the pressure tab', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPressureInsight(tester);

      expect(alertControlOnCard(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PressureCard),
          matching: find.byType(PremiumBadge),
        ),
        findsOneWidget,
      );

      await tapVisible(tester, alertRowOnCard());
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('BaroEase Premium'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('cannot reach the alerts toggle or the export screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      // The Monitoring section sits below the fold, and a row a lazy list has not built yet is a row `find.text` cannot see — scroll first, or the assertion reads "the gate is gone" when the gate is merely further down.
      await scrollIntoView(tester, find.text('Pressure-drop alerts'));

      // - locked rows replace the real controls. Scoped to the alerts row: the
      //   check-in nudge beside it is free and IS a switch.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Pressure-drop alerts'),
            matching: find.byType(PremiumTileGate),
          ),
          matching: find.byType(SwitchListTile),
        ),
        findsNothing,
      );
      expect(find.text('Pressure-drop alerts'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsWidgets);

      // Export is premium in full — the data exports as well as the PDF — so the row is a badge and a paywall, never a path to a file.
      await tapVisible(tester, find.text('Export data'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('BaroEase Premium'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('still gets logging and medications', (tester) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);

      // The export row is covered by the Settings test above, which taps it.
      await openMedications(tester);
      expect(find.text('Medications'), findsOneWidget);

      // Logging works — reachable from the dashboard's hero button.
      await tester.tap(find.byIcon(AppIconConstant.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await openLog(tester);
      expect(find.text('How intense is the pain?'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('the locked alert row opens the paywall, account or not', (
      tester,
    ) async {
      await pumpApp(tester);
      await openPaywallFromAlertRow(tester);

      // The pitch comes first: a login screen must never appear in front of a paywall the user has not been shown yet.
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(find.text('Sign in to unlock Premium'), findsNothing);
      // …and it sells straight away, signed out (App Store 5.1.1(v)).
      expect(find.text(r'$29.99'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('the paywall offers login as an extra, not as the way in', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openPaywallFromAlertRow(tester);

      await tapVisible(
        tester,
        find.text('Sign in to use Premium on your other devices'),
      );
      expect(find.text('Sign in to unlock Premium'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Back on the paywall it was opened from, still selling — the link is gone because there is an account now.
      expect(app.auth.signInCalls, [AuthProviderKind.google]);
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(
        find.text('Sign in to use Premium on your other devices'),
        findsNothing,
      );

      await finishTest(tester);
    });

    testWidgets('backing out of login leaves the paywall standing', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openPaywallFromAlertRow(tester);

      await tapVisible(
        tester,
        find.text('Sign in to use Premium on your other devices'),
      );
      await tapVisible(tester, find.text('Not now'));

      expect(app.auth.signInCalls, isEmpty);
      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(
        find.text('Sign in to use Premium on your other devices'),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('the app_config switch opens alerts to a free account', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedIn: true,
        appConfig: AppConfig(freePressureAlerts: true),
      );
      await openPressureInsight(tester);

      expect(alertControlOnCard(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PressureCard),
          matching: find.byType(PremiumBadge),
        ),
        findsNothing,
      );

      await finishTest(tester);
    });

    testWidgets('an entitlement without an account unlocks the alert row', (
      tester,
    ) async {
      // The combination RevenueCat produces after a purchase nobody signed in for.
      await pumpApp(tester, premium: true, signedIn: false);
      await openPressureInsight(tester);

      expect(alertControlOnCard(), findsOneWidget);

      await finishTest(tester);
    });
  });

  group('premium user', () {
    testWidgets('gets the alerts toggle and the PDF report', (tester) async {
      // Signed in as well as premium: the alerts row takes a paying user to
      // sign-in first, since the server never pushes to an anonymous session
      // (`lib/features/alerts/CLAUDE.md`).
      await pumpApp(tester, premium: true, signedIn: true);
      await openSettings(tester);

      // The Settings row only reports On/Off — the control itself lives on Insights' pressure card, so the row carries no switch of its own.
      expect(
        find.descendant(
          of: find.byType(AlertsSettingsTile),
          matching: find.byType(Switch),
        ),
        findsNothing,
      );

      // The row switches tabs rather than pushing a route (/pressure is gone), so there is nothing to page back from — Settings is reopened below.
      await tapVisible(tester, find.text('Pressure-drop alerts'));
      await pumpCountUp(tester);
      // Past `_AlertControls.highlightHold`, so its timer is not left pending.
      await tester.pump(const Duration(milliseconds: 600));

      // Unlocked means the alert row is built at all: a free user gets one pitch and no controls, which is what makes this the gating assertion.
      // The tag is the marker rather than a `Switch` — the switch and the threshold row were merged into one row that opens the editor, so a `Switch` finder now reads "the gate closed" when the control merely changed shape.
      expect(
        find.descendant(
          of: find.byType(PressureCard),
          matching: find.byType(AlertSummaryTag),
        ),
        findsOneWidget,
      );

      // The row opened the threshold sheet on the way in (`toPressureAlert` switches the tab AND opens the editor for a premium user), and its barrier swallows the nav-bar tap — so Settings is only reachable once the sheet is closed.
      await tester.tap(find.byTooltip('Close'));
      await settleFrames(tester);

      await openSettings(tester);

      // No locked teaser left anywhere on the screen. One badge survives and it is the subscription row's STATUS tag — `PremiumSettingsTile` wears the same pill to say premium is on — so the assertion is where the badge sits, not that none exists: a badge on any other row is a gate that did not open.
      expect(
        find.descendant(
          of: find.byType(PremiumSettingsTile),
          matching: find.byType(PremiumBadge),
        ),
        findsOneWidget,
      );
      expect(find.byType(PremiumBadge), findsOneWidget);

      // The whole export screen is reachable, and the report is offered for real in its picker — no badge, no pitch, just the row that makes it.
      await tapVisible(tester, find.text('Export data'));
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Export'));

      expect(find.text('Doctor report (PDF)'), findsOneWidget);
      expect(find.byType(PremiumBadge), findsNothing);

      await finishTest(tester);
    });
  });
}
