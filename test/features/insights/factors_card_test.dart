import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';

import '../../helpers/pump_app.dart';

/// The Factors tab is free (`docs/PREMIUM_RULES.md`): a free user gets the map
/// itself, never a pitch.
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

  testWidgets('a free user gets the map itself', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seedCheckIns(app);
    await openFactorsInsight(tester);

    // Nothing is being sold on this tab.
    expect(
      find.textContaining('which of your days bring attacks on'),
      findsNothing,
    );
    // Too few attacks to grade anything, so the card says what it is waiting for rather than drawing an empty map.
    expect(find.textContaining('of 15 attacks'), findsOneWidget);
    await finishTest(tester);
  });
}
