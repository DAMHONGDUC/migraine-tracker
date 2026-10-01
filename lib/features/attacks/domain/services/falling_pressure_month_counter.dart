import '../../../../core/constants/home_widget_constant.dart';
import '../entities/attack.dart';

/// How many of this month's attacks came on a day pressure was falling — the line the saved step reads back after a log.
///
/// **Only for an attack that itself came on a falling day.** On any other
/// attack the count is about something that did not just happen, and a number
/// about the weather after a calm-day log would read as the app insisting on a
/// trigger. The month is the saved attack's own local calendar month.
///
/// "Falling" is the same line the home screen widget and the History filter
/// draw: a 24h change at or below `-HomeWidgetConstant.trendThresholdHpa`.
final class FallingPressureMonthCounter {
  const FallingPressureMonthCounter();

  /// The count, the saved attack included; null when [saved] has no reading or did not come on a falling day.
  int? count(Attack saved, Iterable<Attack> all) {
    if (!_isFalling(saved)) return null;

    final DateTime month = saved.startedAt.toLocal();
    final int counted = all
        .where((Attack a) => a.id != saved.id)
        .where((Attack a) {
          final DateTime local = a.startedAt.toLocal();
          return local.year == month.year && local.month == month.month;
        })
        .where(_isFalling)
        .length;

    // The saved attack counts once, whether or not the list already holds it.
    return counted + 1;
  }

  bool _isFalling(Attack attack) {
    final double? delta = attack.weather?.pressureDelta24hHpa;
    return delta != null && delta <= -HomeWidgetConstant.trendThresholdHpa;
  }
}
