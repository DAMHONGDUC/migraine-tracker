import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/weather/current_weather_card.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/daily_log/presentation/screens/daily_log_screen/daily_log_screen.dart';
import 'package:migraine_tracker/features/daily_log/presentation/widgets/daily_check_in_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/risk_forecast_screen/risk_forecast_screen.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/dashboard_log_button.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/month_days_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/risk_score_card.dart';
import 'package:migraine_tracker/features/dashboard/presentation/widgets/week_summary_card.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

/// The 2026-09-30 dashboard: what each redesigned section promises, measured on the screen rather than read off the code.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// A month of history, so the risk score's own fortnight gate is not what is being tested.
  Future<void> seedHistory(PumpedApp app) async {
    final DriftAttackRepository attacks = DriftAttackRepository(app.db);
    final DateTime now = DateTime.now();

    for (final int daysAgo in <int>[30, 20, 10, 3]) {
      await attacks.insert(
        Attack(
          id: 'a$daysAgo',
          startedAt: DateTime(
            now.year,
            now.month,
            now.day - daysAgo,
            9,
          ).toUtc(),
          intensity: 6,
          regions: const <HeadRegion>[HeadRegion.templeR],
        ),
      );
    }
  }

  testWidgets('the log button says what logging costs', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DashboardLogButton),
        matching: find.text('3 taps · works offline'),
      ),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('week and month sit side by side at one height', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await scrollIntoView(tester, find.byType(MonthDaysCard));

    final Rect week = tester.getRect(find.byType(WeekSummaryCard));
    final Rect month = tester.getRect(find.byType(MonthDaysCard));

    expect(week.top, month.top);
    expect(week.height, month.height);
    expect(week.right, lessThan(month.left));

    // Captions and counts on one line each, though only the week's caption carries a chevron.
    expect(
      tester.getRect(find.text('This week')).top,
      tester.getRect(find.text('This month')).top,
    );
    final Finder counts = find.text('0');
    expect(
      tester
          .getRect(
            find.descendant(of: find.byType(WeekSummaryCard), matching: counts),
          )
          .top,
      tester
          .getRect(
            find.descendant(of: find.byType(MonthDaysCard), matching: counts),
          )
          .top,
    );

    await finishTest(tester);
  });

  testWidgets('a sleep answer on the card opens the check-in with it picked', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(DailyCheckInCard),
        matching: find.text('3'),
      ),
    );
    // The route slides in, then the day's row loads and the answer lands on it.
    await settle(tester);
    await settle(tester);

    expect(find.byType(DailyLogScreen), findsOneWidget);
    // The word under the row only appears for the answer that is picked.
    expect(find.text('Okay'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the card stops asking once today is answered', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(DailyCheckInCard),
        matching: find.text('4'),
      ),
    );
    await settle(tester);
    await settle(tester);
    await tapVisible(tester, find.text('Save today'));
    await settle(tester);

    expect(find.byType(DashboardLogButton), findsOneWidget);
    // The card's own line, and the snack bar that said it was saved.
    expect(
      find.descendant(
        of: find.byType(DailyCheckInCard),
        matching: find.text('Today is recorded'),
      ),
      findsOneWidget,
    );
    expect(find.text('How did you sleep?'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('premium: the risk forecast is a compact card of its own', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await seedHistory(app);
    await settle(tester);

    final Finder risk = find.byType(RiskScoreCard);
    expect(risk, findsOneWidget);
    expect(
      find.ancestor(of: risk, matching: find.byType(CurrentWeatherCard)),
      findsNothing,
    );
    expect(find.text('Attack risk forecast'), findsOneWidget);
    // Today's number only — the mini week carries none.
    expect(
      find.descendant(of: risk, matching: find.textContaining('%')),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('tapping the risk card opens the forecast screen', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, premium: true);
    await seedHistory(app);
    await settle(tester);

    await tapVisible(tester, find.byType(RiskScoreCard));
    await settle(tester);

    expect(find.byType(RiskForecastScreen), findsOneWidget);
    // Seven columns, each carrying its own number — plus today's score above them.
    expect(
      find.descendant(
        of: find.byType(RiskForecastScreen),
        matching: find.textContaining('%'),
      ),
      findsAtLeastNWidgets(8),
    );
    expect(find.text('See the pressure forecast'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('free: no risk card and no divider in the weather card', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    await seedHistory(app);
    await settle(tester);

    expect(find.byType(RiskScoreCard), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CurrentWeatherCard),
        matching: find.byType(SdDividerV2),
      ),
      findsNothing,
    );

    await finishTest(tester);
  });

  testWidgets('the outlook sits directly under the log button', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    final double logBottom = tester
        .getRect(find.byType(DashboardLogButton))
        .bottom;
    final double weatherTop = tester
        .getRect(find.byType(CurrentWeatherCard))
        .top;
    final double checkInTop = tester.getRect(find.byType(DailyCheckInCard)).top;

    expect(weatherTop, greaterThan(logBottom));
    expect(checkInTop, greaterThan(weatherTop));

    await finishTest(tester);
  });
}
