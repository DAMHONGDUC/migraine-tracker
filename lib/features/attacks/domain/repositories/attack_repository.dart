import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/attack.dart';

/// Contract for attack storage. Features depend on this, never on the Drift
/// implementation — the sync phase will decorate it with a cloud-syncing one.
abstract interface class AttackRepository {
  /// All attacks, newest first, with their weather snapshot when present.
  Stream<List<Attack>> watchAll();

  /// Inserts the attack and, if already available, its weather snapshot.
  /// Works fully offline: [Attack.weather] may simply be null.
  Future<void> insert(Attack attack);

  /// Backfills the weather snapshot for an attack logged offline.
  Future<void> attachWeather(String attackId, WeatherSnapshot weather);

  /// Attacks still waiting for a weather snapshot (offline backfill queue).
  Future<List<Attack>> attacksMissingWeather();

  /// GDPR wipe.
  Future<void> deleteAll();
}
