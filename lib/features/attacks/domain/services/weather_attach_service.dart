import '../../../../core/logging/app_logger.dart';
import '../../../weather/domain/repositories/weather_repository.dart';
import '../entities/attack.dart';
import '../repositories/attack_repository.dart';

/// Best-effort weather attachment (hard rule 4: logging never waits for the
/// network). Every method swallows failures — a missing snapshot is always
/// recoverable via [backfillMissing] on a later launch.
class WeatherAttachService {
  const WeatherAttachService(this._attacks, this._weather);

  final AttackRepository _attacks;
  final WeatherRepository _weather;

  /// Called right after an attack is saved. On success also retries any
  /// older attacks still missing weather, since we clearly have network.
  Future<void> onAttackLogged(Attack attack) async {
    try {
      final snapshot = await _weather.snapshotAt(attack.startedAt);
      if (snapshot == null) {
        AppLogger.info('No weather snapshot yet; will backfill', attack.id);
        return;
      }
      await _attacks.attachWeather(attack.id, snapshot);
      AppLogger.info('Weather attached to attack', attack.id);
      await backfillMissing();
    } on Exception catch (error, stackTrace) {
      // Swallow: the attack is already saved; weather comes later.
      AppLogger.warning('Weather attach failed (will retry later)', error);
      AppLogger.debug('Weather attach stack', stackTrace);
    }
  }

  /// Fetches the weather each offline-logged attack was missing — at the
  /// attack's own start time, never today's weather.
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
