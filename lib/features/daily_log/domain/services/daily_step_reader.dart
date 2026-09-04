import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../health/domain/entities/step_day.dart';
import '../../../health/domain/repositories/health_repository.dart';

/// The day's step count for a check-in, or null when Apple Health had nothing to give.
///
/// Null and 0 stay different answers all the way through, exactly as they do on
/// an attack: null is a day Health would not talk about, zero is a day spent
/// still. Sleep has no counterpart here — it is read for display and never
/// stored (`features/health/CLAUDE.md`).
class DailyStepReader {
  const DailyStepReader(this._health);

  final HealthRepository _health;

  Future<int?> stepsFor(DateTime day) async {
    if (!_health.isAvailable) return null;

    final DateTime midnight = DateTime(day.year, day.month, day.day);
    final DateTime end = DateTime(day.year, day.month, day.day, 23, 59, 59);

    try {
      final List<StepDay> days = await _health.stepDays(from: midnight, to: end);

      if (days.isEmpty) {
        SdLogger.info(LogTagConstant.dailyLog, 'No step data for this day', {
          'day': midnight.toIso8601String(),
        });
        return null;
      }
      // Summed rather than `.first`, so a window that ever spans a midnight cannot silently drop half of itself.
      return days.fold<int>(0, (int sum, StepDay each) => sum + each.count);
    } catch (error, stackTrace) {
      // The check-in is the user's three answers; a step count is a bonus, so a failure here must not cost the save.
      SdLogger.warning(
        LogTagConstant.dailyLog,
        'Reading the day\'s steps failed; the check-in keeps none',
        error,
      );
      SdLogger.debug(LogTagConstant.dailyLog, 'Daily step read stack', stackTrace);
      return null;
    }
  }
}
