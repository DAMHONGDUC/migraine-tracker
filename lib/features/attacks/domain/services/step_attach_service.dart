import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../health/domain/entities/step_day.dart';
import '../../../health/domain/repositories/health_repository.dart';
import '../entities/attack.dart';
import '../repositories/attack_repository.dart';

/// Puts the day's step count on an attack the moment it is logged.
///
/// Best-effort in the same shape as `WeatherAttachService`, and for a
/// stricter reason: hard rule 4 says nothing in the log flow waits, and this
/// one reads HealthKit, which asks another process. The attack is already
/// saved before this runs, so every failure here costs a number, never a
/// record.
///
/// **No backfill, unlike weather.** A missing snapshot can be fetched later
/// for the time it belonged to; a missing step count cannot. The figure is
/// "steps taken before this attack", and HealthKit would happily answer with
/// the whole day's total instead — a different number filed under the same
/// name. Better absent than wrong.
class StepAttachService {
  const StepAttachService(this._attacks, this._health);

  final AttackRepository _attacks;
  final HealthRepository _health;

  Future<void> onAttackLogged(Attack attack) async {
    if (!_health.isAvailable) return;

    try {
      final DateTime loggedAt = attack.startedAt.toLocal();
      final DateTime midnight = DateTime(
        loggedAt.year,
        loggedAt.month,
        loggedAt.day,
      );
      // Midnight to the log, not the whole day: what matters beside an attack
      // is how much the person had moved before it.
      final List<StepDay> days = await _health.stepDays(
        from: midnight,
        to: loggedAt,
      );

      if (days.isEmpty) {
        SdLogger.info(
          LogTagConstant.attackLog,
          'No step data for this attack',
          attack.id,
        );
        return;
      }

      // One window, one day — but sum rather than take `.first`, so a window
      // that ever spans a midnight cannot silently drop half of itself.
      final int steps = days.fold(0, (int sum, StepDay day) => sum + day.count);
      await _attacks.attachSteps(attack.id, steps);
      SdLogger.info(LogTagConstant.attackLog, 'Steps attached to attack', {
        'attack': attack.id,
        'steps': steps,
      });
    } on Exception catch (error, stackTrace) {
      // Swallow: the attack is saved, and this number is never coming back
      // (see the class doc), so there is nothing to retry and nothing to fail.
      SdLogger.warning(
        LogTagConstant.attackLog,
        'Step attach failed; the attack keeps no step count',
        error,
      );
      SdLogger.debug(LogTagConstant.attackLog, 'Step attach stack', stackTrace);
    }
  }
}
