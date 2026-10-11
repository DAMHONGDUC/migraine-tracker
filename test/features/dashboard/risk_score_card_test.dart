import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

import '../../helpers/pump_app.dart';

/// The dashboard's risk card is free (`docs/PREMIUM_RULES.md`): every user gets
/// it, told what it is waiting for until there is history to score.
void main() {
  Attack attackDaysAgo(int daysAgo) {
    final DateTime now = DateTime.now();

    return Attack(
      id: 'a$daysAgo',
      startedAt: DateTime(now.year, now.month, now.day - daysAgo, 9).toUtc(),
      intensity: 6,
      regions: const <HeadRegion>[HeadRegion.templeR],
    );
  }

  /// A month of history, so the score's own fortnight gate is not what is being tested.
  Future<void> seedHistory(PumpedApp app) async {
    final DriftAttackRepository attacks = DriftAttackRepository(app.db);

    for (final int daysAgo in <int>[30, 20, 10, 3]) {
      await attacks.insert(attackDaysAgo(daysAgo));
    }
  }

  testWidgets('a free user gets the card once there is history behind it', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedHistory(app);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Attack risk forecast'), findsOneWidget);
    await finishTest(tester);
  });

  // A score with nothing behind it would be a number the user cannot check.
  testWidgets('with no history it is told what it is waiting for', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Attack risk forecast'), findsOneWidget);
    expect(
      find.text('Two weeks of logging and the score starts.'),
      findsOneWidget,
    );
    await finishTest(tester);
  });
}
