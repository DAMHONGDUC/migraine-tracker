import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';

import '../../helpers/pump_app.dart';

/// The Factors tab is premium in full, and this is the test that proves a free
/// user's tree never holds the map — not blurred, not offscreen, not built and
/// hidden (`docs/rules/TESTING.md`, item 4).
void main() {
  DateTime dayOf(int daysAgo) {
    final DateTime now = DateTime.now();

    return DateTime(now.year, now.month, now.day - daysAgo);
  }

  /// Enough answered days for the map to have something to draw, if it were allowed to.
  Future<void> seedCheckIns(PumpedApp app) async {
    final DriftDailyLogRepository logs = DriftDailyLogRepository(app.db);

    for (int i = 0; i < 30; i++) {
      await logs.save(
        DailyLog(
          day: dayOf(i),
          sleepQuality: 2,
          stressLevel: 4,
          factors: const <DailyFactor>[DailyFactor.alcohol],
        ),
      );
    }
  }

  testWidgets('a free user gets the pitch and none of the map', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedCheckIns(app);
    await openFactorsInsight(tester);

    // The offer, and the badge that says what it is.
    expect(find.text('Premium'), findsWidgets);
    expect(
      find.textContaining('which of your days bring attacks on'),
      findsOneWidget,
    );
    // None of the map's own vocabulary may exist anywhere in the tree.
    expect(find.text('More attacks'), findsNothing);
    expect(find.text('Fewer attacks'), findsNothing);
    expect(find.text('No difference'), findsNothing);
    expect(find.text('Alcohol'), findsNothing);
    await finishTest(tester);
  });

  testWidgets('premium gets the map itself', (tester) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await seedCheckIns(app);
    await openFactorsInsight(tester);

    // Nothing is being sold on a tab the user already owns.
    expect(
      find.textContaining('which of your days bring attacks on'),
      findsNothing,
    );
    // Too few attacks to grade anything, so the card says what it is waiting for rather than drawing an empty map.
    expect(find.textContaining('of 15 attacks'), findsOneWidget);
    await finishTest(tester);
  });
}
