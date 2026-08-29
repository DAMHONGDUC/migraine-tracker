import '../../../../core/constants/home_widget_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../dashboard/domain/services/week_summary_calculator.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../entities/home_widget_snapshot.dart';

/// Turns the app's own data into what the home-screen widget shows. Pure Dart — the numbers are decided here, the wording elsewhere.
class HomeWidgetSnapshotBuilder {
  const HomeWidgetSnapshotBuilder({
    this.weeks = const WeekSummaryCalculator(),
  });

  /// The dashboard's own calculator, so the widget's count and the card's can never disagree about where a week starts.
  final WeekSummaryCalculator weeks;

  HomeWidgetSnapshot build({
    required List<Attack> attacks,
    required DailyPressure? pressure,
    required DateTime now,
  }) {
    final int weekCount = weeks.compute(attacks, now: now).thisWeekCount;
    final DateTime? expiresAt = pressure?.day.add(
      HomeWidgetConstant.pressureMaxAge,
    );

    // A row survives however long the phone stayed shut, so the widget shows its dash rather than last week's weather as today's.
    if (pressure == null || expiresAt == null || !expiresAt.isAfter(now)) {
      return HomeWidgetSnapshot(weekCount: weekCount);
    }

    return HomeWidgetSnapshot(
      weekCount: weekCount,
      pressureHpa: pressure.pressureHpa,
      pressureDelta24hHpa: pressure.pressureDelta24hHpa,
      pressureExpiresAt: expiresAt,
    );
  }
}
