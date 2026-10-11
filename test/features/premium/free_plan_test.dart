import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/core/widgets/medication_name_dialog.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';

import '../../helpers/pump_app.dart';

/// The free plan has no record limits (`docs/PREMIUM_RULES.md`).
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
  testWidgets('a free user logs with no limit at all', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    // Far past the old 40-attack cap.
    await seedAttacks(app, 45);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await openLog(tester);

    expect(find.text('BaroEase Premium'), findsNothing);
    expect(find.text('How intense is the pain?'), findsOneWidget);

    await finishTest(tester);
  });

  // Six: one past the five the free plan used to hold.
  testWidgets('a sixth medication goes straight to the name dialog', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedMedications(app, 5);
    await tester.pump();
    await openMedications(tester);

    await tapVisible(tester, find.byIcon(AppIconConstant.add));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MedicationNameDialog), findsOneWidget);
    expect(find.textContaining('on the free plan'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('the log flow adds a sixth medication too', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedMedications(app, 5);
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

    expect(find.byType(MedicationNameDialog), findsOneWidget);

    await finishTest(tester);
  });
}
