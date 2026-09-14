import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';

import '../../helpers/pump_app.dart';

/// The check-in is free for everyone, and the dashboard card is what asks.
void main() {
  testWidgets('the dashboard asks, whatever plan the user is on', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('How was today?'), findsOneWidget);
    // Nothing about it is sold: no badge, no lock, on either plan.
    expect(find.text('Thirty seconds, attack or not.'), findsOneWidget);
    await finishTest(tester);
  });

  // A card that vanished on save would read as the app forgetting what it was just told.
  testWidgets('once today is answered the card says so instead of asking', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);

    await DriftDailyLogRepository(
      app.db,
    ).save(DailyLog(day: DateTime.now(), sleepQuality: 3, stressLevel: 2));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Today is recorded'), findsOneWidget);
    expect(find.text('How was today?'), findsNothing);
    await finishTest(tester);
  });

  // A row Apple Health filled in with a step count is not a check-in, and the card must keep asking.
  testWidgets('a row holding only a step count still counts as unanswered', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);

    await DriftDailyLogRepository(
      app.db,
    ).save(DailyLog(day: DateTime.now(), steps: 4200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('How was today?'), findsOneWidget);
    await finishTest(tester);
  });
}
