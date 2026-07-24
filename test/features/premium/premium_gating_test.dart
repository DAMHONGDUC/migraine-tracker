import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
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

Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.insights_outlined));
  // Stream emits → card builds → count-up runs (700ms). Pump in real frames,
  // not one big jump: a single large pump skips the count-up's start frame.
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openMedications(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.medication_outlined));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
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

      // Locked rows in place of the real controls.
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Get a push before a big pressure drop hits.'),
          findsOneWidget);
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

    testWidgets('tapping Unlock opens the paywall', (tester) async {
      final app = await pumpApp(tester);
      await seedInsightData(tester, app);
      await openInsights(tester);

      await tester.tap(find.text('Unlock').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('BaroEase Premium'), findsOneWidget);
      expect(find.text('Know your storm before it hits'), findsOneWidget);

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
          find.text(
            'Unlock to see how much of your pain follows the weather.',
          ),
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

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Doctor report (PDF)'), findsOneWidget);
      expect(find.text('Premium'), findsNothing);

      await finishTest(tester);
    });
  });
}
