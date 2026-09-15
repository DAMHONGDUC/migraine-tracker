import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/premium_banner.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../helpers/pump_app.dart';

/// Every screen, checked for the one bug a green suite never reports.
///
/// A `RenderFlex` overflow is a `FlutterError` thrown during layout, not a
/// failed expectation: the test binding records it and the run stays green
/// unless something asks. Nothing asked, which is how the paywall shipped 49px
/// of striped bar across the bottom of the screen that sells the app — found
/// only because an unrelated premium test happened to pump it.
///
/// So this file pumps each surface and asks. It asserts nothing about what a
/// screen looks like, which is what keeps it useful while the redesign moves
/// things: a screen that changes completely still has to fit.
///
/// The size is `pumpApp`'s own 393x852 — the design size everything is drawn
/// for, so an overflow here is unambiguous rather than a device the app was
/// never laid out for.
Future<void> expectNoOverflow(WidgetTester tester, String surface) async {
  await settleFrames(tester);

  final Object? error = tester.takeException();

  expect(
    error,
    isNull,
    reason: '$surface overflowed or threw during layout: $error',
  );
}

/// Enough history for the cards that only draw once there is data — an empty
/// screen is the one layout that never overflows.
Future<void> seedHistory(PumpedApp app) async {
  final DriftAttackRepository repository = DriftAttackRepository(app.db);

  for (int i = 0; i < 15; i++) {
    final DateTime startedAt = DateTime.now().toUtc().subtract(
      Duration(days: i),
    );
    await repository.insert(
      Attack(
        id: 'seed-$i',
        startedAt: startedAt,
        intensity: 3 + (i % 7),
        regions: const <HeadRegion>[HeadRegion.templeL, HeadRegion.crown],
        medicationName: 'Sumatriptan',
        symptoms: const <String>['aura', 'nausea'],
        notes: 'a longer note, the kind a real user writes when it was bad',
        weather: WeatherSnapshot(
          capturedAt: startedAt,
          pressureHpa: 1004.2,
          pressureDelta24hHpa: i.isEven ? -7.5 : 2.3,
          humidityPercent: 71,
          temperatureCelsius: 19.3,
        ),
      ),
    );
  }
}

void main() {
  // Both entitlements, because they are different trees: a free user gets
  // pitches where a subscriber gets charts, and either can be the one that
  // does not fit.
  for (final (String plan, bool premium) in <(String, bool)>[
    ('free', false),
    ('premium', true),
  ]) {
    group('$plan user', () {
      testWidgets('the dashboard fits', (tester) async {
        final PumpedApp app = await pumpApp(tester, premium: premium);
        await seedHistory(app);

        await expectNoOverflow(tester, 'Dashboard');

        await finishTest(tester);
      });

      testWidgets('History fits, as a list and as charts', (tester) async {
        final PumpedApp app = await pumpApp(tester, premium: premium);
        await seedHistory(app);

        await openHistory(tester);
        await expectNoOverflow(tester, 'History list');

        await openHistoryCharts(tester);
        await expectNoOverflow(tester, 'History charts');

        await finishTest(tester);
      });

      testWidgets('every Insights tab fits', (tester) async {
        final PumpedApp app = await pumpApp(
          tester,
          premium: premium,
          healthAvailable: true,
        );
        await seedHistory(app);

        await openPressureInsight(tester);
        await expectNoOverflow(tester, 'Insights — pressure');

        await openSleepInsight(tester);
        await expectNoOverflow(tester, 'Insights — sleep');

        await openActivityInsight(tester);
        await expectNoOverflow(tester, 'Insights — activity');

        await openFactorsInsight(tester);
        await expectNoOverflow(tester, 'Insights — factors');

        await finishTest(tester);
      });

      testWidgets('Medications fits, list and detail', (tester) async {
        await pumpApp(tester, premium: premium);

        await openMedications(tester);
        await addMedication(tester, 'Sumatriptan');
        await expectNoOverflow(tester, 'Medications list');

        await openMedication(tester, 'Sumatriptan');
        await expectNoOverflow(tester, 'Medication detail');

        await finishTest(tester);
      });

      testWidgets('Settings fits, top to bottom', (tester) async {
        await pumpApp(tester, premium: premium, healthAvailable: true);

        await openSettings(tester);
        await expectNoOverflow(tester, 'Settings');

        // The sections below the fold are not built until they are reached, so
        // an overflow down there is invisible without the scroll.
        await scrollIntoView(tester, find.text('About BaroEase'));
        await expectNoOverflow(tester, 'Settings, scrolled');

        await finishTest(tester);
      });

      testWidgets('the notification list fits', (tester) async {
        await pumpApp(tester, premium: premium);

        await openNotifications(tester);
        await expectNoOverflow(tester, 'Notifications');

        await finishTest(tester);
      });

      testWidgets('the log flow fits at every step', (tester) async {
        await pumpApp(tester, premium: premium);

        await openLog(tester);
        await expectNoOverflow(tester, 'Log — intensity');

        await tester.tap(find.text('7'));
        await settleFrames(tester);
        await expectNoOverflow(tester, 'Log — location');

        await tester.tap(find.text('Crown').last);
        await settleFrames(tester);
        await tester.tap(find.text('Next'));
        await settleFrames(tester);
        await expectNoOverflow(tester, 'Log — medication');

        await finishTest(tester);
      });
    });
  }

  // Not per-plan: the paywall is only ever shown to somebody who has not paid,
  // and it is where the overflow this file exists for actually shipped.
  testWidgets('the paywall fits', (tester) async {
    await pumpApp(tester);
    await settleFrames(tester);

    // The dashboard's premium banner is the free user's own door to it, and
    // the only one that needs no seeded data to appear.
    await tapVisible(tester, find.byType(PremiumBanner));
    await settleFrames(tester);

    expect(find.text('BaroEase Premium'), findsOneWidget);
    await expectNoOverflow(tester, 'Paywall');

    await finishTest(tester);
  });

  testWidgets('the export screen fits', (tester) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await seedHistory(app);

    await openExportScreen(tester);
    await settleExport(tester);
    await expectNoOverflow(tester, 'Export');

    await finishTest(tester);
  });
}
