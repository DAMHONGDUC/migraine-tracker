import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/premium_limit_constant.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';

import '../../helpers/pump_app.dart';

/// The free plan's record limits.
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

/// One attack from before the free plan's 90-day window — what the banner and
/// the blurred row both exist for.
Future<void> seedOldAttack(PumpedApp app) async {
  await DriftAttackRepository(app.db).insert(
    Attack(
      id: 'old',
      startedAt: DateTime.now().toUtc().subtract(
        PremiumLimitConstant.freeHistoryWindow + const Duration(days: 5),
      ),
      intensity: 7,
      regions: const <HeadRegion>[HeadRegion.templeR],
    ),
  );
}

Future<void> seedMedications(PumpedApp app, int count) async {
  final DriftMedicationRepository repo = DriftMedicationRepository(app.db);

  for (int i = 0; i < count; i++) {
    await repo.upsert(Medication(id: 'm$i', name: 'Med $i'));
  }
}

void main() {
  group('the free history window', () {
    testWidgets('a free user logs with no limit at all', (tester) async {
      final PumpedApp app = await pumpApp(tester);
      // Far past the old 40-attack cap: logging is never refused now.
      await seedAttacks(app, 45);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await openLog(tester);

      expect(find.text('BaroEase Premium'), findsNothing);
      expect(find.text('How intense is the pain?'), findsOneWidget);

      await finishTest(tester);
    });

    testWidgets('nothing is said while the window hides nothing', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester);
      await seedAttacks(app, 5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('are locked'), findsNothing);

      await finishTest(tester);
    });

    testWidgets('an attack older than the window is named by the banner', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester);
      await seedAttacks(app, 2);
      await seedOldAttack(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The banner says what Premium would open, and that nothing was deleted.
      // The ROW behind the window is a second door onto the same offer, and
      // is covered by `history/locked_history_test.dart`.
      expect(find.textContaining('are locked'), findsWidgets);
      expect(find.textContaining('History locked'), findsWidgets);

      await finishTest(tester);
    });

    testWidgets('premium reads the old attack and shows no banner', (
      tester,
    ) async {
      final PumpedApp app = await pumpApp(tester, premium: true);
      await seedAttacks(app, 2);
      await seedOldAttack(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('are locked'), findsNothing);

      await finishTest(tester);
    });
  });

  group('the medication limit', () {
    testWidgets('names itself on the medications tab', (tester) async {
      final PumpedApp app = await pumpApp(tester);
      await seedMedications(app, PremiumLimitConstant.medications);
      await tester.pump();
      await openMedications(tester);

      await tapVisible(tester, find.byIcon(AppIconConstant.add));
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
