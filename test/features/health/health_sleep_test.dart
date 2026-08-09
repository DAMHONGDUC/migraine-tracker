import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/widgets/premium_gate.dart';
import 'package:migraine_tracker/core/widgets/settings_tile.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/enums/health_data_kind.dart';

import '../../helpers/pump_app.dart';

/// The sleep connect switch, which lives on the sleep detail screen now —
/// steps have their own on the activity screen, so name the row it sits in.
Finder healthSwitch() => find.ancestor(
  of: find.text('Apple Health sleep'),
  matching: find.byType(SwitchListTile),
);

/// Local midnight [daysAgo] back — the morning a night ended.
DateTime morning(int daysAgo) {
  final DateTime now = DateTime.now();

  return DateTime(now.year, now.month, now.day - daysAgo);
}

SleepNight sleptFor(int daysAgo, {required double hours}) => SleepNight(
  date: morning(daysAgo),
  duration: Duration(minutes: (hours * 60).round()),
);

Attack attackOnMorning(int daysAgo) {
  final DateTime date = morning(daysAgo);

  return Attack(
    id: 'attack-$daysAgo',
    startedAt: DateTime(date.year, date.month, date.day, 10),
    intensity: 6,
    location: HeadLocation.left,
  );
}

void main() {
  group('Settings row', () {
    testWidgets('is absent where HealthKit is not available', (tester) async {
      await pumpApp(tester, premium: true);
      await openSettings(tester);

      expect(find.text('Sleep'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('is locked for free users, with no way through', (
      tester,
    ) async {
      await pumpApp(tester, healthAvailable: true);
      await openSettings(tester);

      expect(find.text('Sleep'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Sleep'),
          matching: find.byType(SettingsTile),
        ),
        findsOneWidget,
      );
      expect(find.byType(PremiumBadge), findsWidgets);

      await finishTest(tester);
    });

    testWidgets('a premium user can connect sleep from the detail screen', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
      );
      await openSleepScreen(tester);

      await tapVisible(tester, healthSwitch());
      await tester.pump(const Duration(milliseconds: 100));

      expect(app.health.authorizationRequests, 1);
      // One sheet, for sleep alone: steps are a separate switch.
      expect(app.health.requestedKinds, <HealthDataKind>[HealthDataKind.sleep]);
      expect(app.prefs.getBool(PrefsKeyConstant.healthSleep), isTrue);
      expect(app.prefs.getBool(PrefsKeyConstant.healthSteps), isNot(isTrue));
      expect(tester.widget<SwitchListTile>(healthSwitch()).value, isTrue);

      await finishTest(tester);
    });

    testWidgets('a refused HealthKit sheet leaves the switch off', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
      );
      app.health.authorizes = false;
      await openSleepScreen(tester);

      await tapVisible(tester, healthSwitch());
      await tester.pump(const Duration(milliseconds: 100));

      expect(app.prefs.getBool(PrefsKeyConstant.healthSleep), isNot(isTrue));
      expect(find.text("Couldn't connect to Apple Health."), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('the old single flag still counts as connected', (
      tester,
    ) async {
      // Someone who connected before sleep and steps split apart must not
      // find themselves silently disconnected.
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          PrefsKeyConstant.healthConnected: true,
        },
      );
      await openSleepScreen(tester);

      expect(tester.widget<SwitchListTile>(healthSwitch()).value, isTrue);
      expect(app.health.authorizationRequests, 0);

      await finishTest(tester);
    });
  });

  group('Insights card', () {
    testWidgets('is absent where HealthKit is not available', (tester) async {
      await pumpApp(tester, premium: true);
      await openInsights(tester);

      expect(find.text('Sleep & attacks'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('a free user never reaches a HealthKit read', (tester) async {
      final PumpedApp app = await pumpApp(
        tester,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          PrefsKeyConstant.healthConnected: true,
        },
      );
      await openInsights(tester);

      // The gate shows its pitch; nothing behind it was built or fetched.
      expect(find.text('Sleep & attacks'), findsNothing);
      expect(app.health.sleepReads, 0);

      await finishTest(tester);
    });

    testWidgets('prompts a premium user to connect Apple Health', (
      tester,
    ) async {
      await pumpApp(tester, premium: true, healthAvailable: true);
      await openInsights(tester);

      expect(find.text('Sleep & attacks'), findsOneWidget);
      expect(
        find.textContaining('Connect Apple Health sleep in Settings'),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('shows the two averages once there is enough sleep data', (
      tester,
    ) async {
      // 5 nights before an attack at 5h, 10 quiet nights at 8h → 3h short.
      final PumpedApp app = await pumpApp(
        tester,
        premium: true,
        healthAvailable: true,
        initialPrefs: const <String, Object>{
          PrefsKeyConstant.healthSleep: true,
        },
        sleepNights: <SleepNight>[
          for (int i = 1; i <= 5; i++) sleptFor(i, hours: 5),
          for (int i = 6; i <= 15; i++) sleptFor(i, hours: 8),
        ],
      );
      final DriftAttackRepository repository = DriftAttackRepository(app.db);

      for (int i = 1; i <= 5; i++) {
        await repository.insert(attackOnMorning(i));
      }

      await openInsights(tester);

      expect(find.text('3h 0m'), findsOneWidget);
      expect(
        find.text('less sleep on the nights before an attack.'),
        findsOneWidget,
      );
      expect(find.text('5h 0m'), findsOneWidget);
      expect(find.text('8h 0m'), findsOneWidget);
      expect(
        find.text('Based on 5 nights before an attack and 10 others'),
        findsOneWidget,
      );

      await finishTest(tester);
    });
  });
}
