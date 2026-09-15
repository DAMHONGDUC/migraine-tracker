import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../weather/domain/repositories/weather_repository.dart';
import '../entities/attack.dart';
import '../repositories/attack_repository.dart';

/// Best-effort weather attachment (hard rule 4: logging never waits for the network).
class WeatherAttachService {
  const WeatherAttachService(this._attacks, this._weather);

  final AttackRepository _attacks;
  final WeatherRepository _weather;

  /// Called right after an attack is saved. On success also retries any older attacks still missing weather, since we clearly have network.
  Future<void> onAttackLogged(Attack attack) =>
      _attach(attack.id, attack.startedAt);

  /// The start time was corrected, so the snapshot that belonged to the old instant is already gone (the repository drops it in the same transaction as the edit).
  ///
  /// Takes the id and the instant rather than an [Attack], because the caller
  /// holds the new time before any stream has replayed it.
  Future<void> onStartedAtChanged(String attackId, DateTime startedAt) =>
      _attach(attackId, startedAt);

  Future<void> _attach(String attackId, DateTime startedAt) async {
    try {
      final snapshot = await _weather.snapshotAt(startedAt);
      if (snapshot == null) {
        SdLogger.info(
          LogTagConstant.weatherAttach,
          'No weather snapshot yet; will backfill',
          attackId,
        );
        return;
      }
      await _attacks.attachWeather(attackId, snapshot);
      SdLogger.info(
        LogTagConstant.weatherAttach,
        'Weather attached to attack',
        attackId,
      );
      await backfillMissing();
    } on Exception catch (error, stackTrace) {
      // Swallow: the attack is already saved; weather comes later.
      SdLogger.warning(
        LogTagConstant.weatherAttach,
        'Weather attach failed (will retry later)',
        error,
      );
      SdLogger.debug(
        LogTagConstant.weatherAttach,
        'Weather attach stack',
        stackTrace,
      );
    }
  }

  /// Fetches the weather each offline-logged attack was missing — at the attack's own start time, never today's weather.
  Future<void> backfillMissing() async {
    final List<Attack> missing;
    try {
      missing = await _attacks.attacksMissingWeather();
    } on Exception {
      return;
    }
    for (final attack in missing) {
      try {
        final snapshot = await _weather.snapshotAt(attack.startedAt);
        if (snapshot != null) {
          await _attacks.attachWeather(attack.id, snapshot);
        }
      } on Exception {
        // Skip this attack; the next backfill pass will retry it.
      }
    }
  }
}
