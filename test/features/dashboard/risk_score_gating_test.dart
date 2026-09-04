import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/risk_score_card.dart';

import '../../helpers/pump_app.dart';

/// The dashboard's risk card is premium, and **absent** rather than locked for
/// everyone else: the premium banner is that screen's one door, and a second
/// locked card would be two pitches for one purchase.
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

  testWidgets('a free user never gets the card at all', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedHistory(app);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RiskScoreCard), findsOneWidget);
    // The widget is placed but renders nothing — no title, no band, no number.
    expect(find.text('Attack risk forecast'), findsNothing);
    expect(find.text('Next 7 days · a prediction'), findsNothing);
    expect(find.text('Low'), findsNothing);
    expect(find.text('Moderate'), findsNothing);
    expect(find.text('High'), findsNothing);
    await finishTest(tester);
  });

  testWidgets('premium gets the card once there is history behind it', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await seedHistory(app);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Attack risk forecast'), findsOneWidget);
    await finishTest(tester);
  });

  // A score with nothing behind it would be a number the user cannot check.
  testWidgets('premium with no history is told what it is waiting for', (
    tester,
  ) async {
    await pumpApp(tester, premium: true);
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
