import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/premium_limit_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';

import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

/// The free plan's record limits. What matters at every one of them is the
/// order: the limit is named first, and the paywall only follows if the user
/// asks for it — the buttons that raise these say "Add medication" or they
/// are the log button, never "buy".
Future<void> seedAttacks(PumpedApp app, int count) async {
  final DriftAttackRepository repo = DriftAttackRepository(app.db);

  for (int i = 0; i < count; i++) {
    await repo.insert(
      Attack(
        id: 'a$i',
        startedAt: DateTime.now().toUtc().subtract(Duration(hours: i + 1)),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
  }
}

Future<void> seedMedications(PumpedApp app, int count) async {
  final DriftMedicationRepository repo = DriftMedicationRepository(app.db);

  for (int i = 0; i < count; i++) {
    await repo.upsert(Medication(id: 'm$i', name: 'Med $i'));
  }
}

void main() {
  group('the attack limit', () {
    testWidgets('lets a free user log while there is room', (tester) async {
      final PumpedApp app = await pumpApp(tester);
      await seedAttacks(app, PremiumLimitConstant.attacks - 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await openLog(tester);

      expect(find.text('BaroEase Premium'), findsNothing);
      expect(find.text('How intense is the pain?'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('counts down the last few logs on the dashboard', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester);
      // The wall lands mid-attack, so it must never be the first the user
      // hears of it.
      await seedAttacks(
        app,
        PremiumLimitConstant.attacks - PremiumLimitConstant.attacksWarnAt,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('${PremiumLimitConstant.attacksWarnAt} logs left on the '
            'free plan'),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('names the limit at the wall, and pitches only on request', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester);
      await seedAttacks(app, PremiumLimitConstant.attacks);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await openLog(tester);

      expect(
        find.text('${PremiumLimitConstant.attacks} attacks on the free plan'),
        findsOneWidget,
      );
      expect(find.text('How intense is the pain?'), findsNothing);
      expect(find.text('BaroEase Premium'), findsNothing);

      // Scoped to the dialog: the dashboard's own countdown banner carries
      // an "Unlock" button too, and it is still in the tree underneath.
      await tester.tap(
        find.descendant(
          of: find.byType(SdDialogV2),
          matching: find.text('Unlock'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('BaroEase Premium'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('premium logs past the limit with no banner', (tester) async {
      final PumpedApp app = await pumpApp(tester, premium: true);
      await seedAttacks(app, PremiumLimitConstant.attacks + 5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('logs left'), findsNothing);

      await openLog(tester);
      expect(find.text('How intense is the pain?'), findsOneWidget);

      await finishTest(tester);
    });
  });

  group('the medication limit', () {
    testWidgets('names itself on the medications tab', (tester) async {
      final PumpedApp app = await pumpApp(tester);
      await seedMedications(app, PremiumLimitConstant.medications);
      await tester.pump();
      await openMedications(tester);

      await tapVisible(tester, find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(
          '${PremiumLimitConstant.medications} medications on the free plan',
        ),
        findsOneWidget,
      );

      await finishTest(tester);
    });

    testWidgets('names itself inside the log flow, and the log still saves', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester);
      await seedMedications(app, PremiumLimitConstant.medications);
      await tester.pump();

      await openLog(tester);
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Right temple'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tapVisible(tester, find.text('Add a medication'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text(
          '${PremiumLimitConstant.medications} medications on the free plan',
        ),
        findsOneWidget,
      );

      // The gate names the limit; it must not take the flow with it.
      await tapVisible(tester, find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('No medication').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Next'), findsOneWidget);

      await finishTest(tester);
    });
  });
}
