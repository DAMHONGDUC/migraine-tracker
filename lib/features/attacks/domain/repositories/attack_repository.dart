import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/attack.dart';
import '../enums/exertion_level.dart';
import '../enums/head_location.dart';

/// Contract for attack storage. Features depend on this, never on the Drift
/// implementation — the sync phase will decorate it with a cloud-syncing one.
abstract interface class AttackRepository {
  /// All attacks, newest first, with their weather snapshot when present.
  Stream<List<Attack>> watchAll();

  /// One-shot read of everything [watchAll] would emit (e.g. for export).
  Future<List<Attack>> getAll();

  /// A single attack (with its weather), or null if it no longer exists —
  /// e.g. deleted from another screen while the detail view was open.
  Stream<Attack?> watchById(String id);

  /// Inserts the attack and, if already available, its weather snapshot.
  /// Works fully offline: [Attack.weather] may simply be null.
  Future<void> insert(Attack attack);

  /// Backfills the weather snapshot for an attack logged offline.
  Future<void> attachWeather(String attackId, WeatherSnapshot weather);

  /// Attacks still waiting for a weather snapshot (offline backfill queue).
  Future<List<Attack>> attacksMissingWeather();

  /// Fills in the optional detail fields added after the 3-tap flow saved.
  Future<void> updateDetails(
    String id, {
    required List<String> symptoms,
    required List<String> triggers,
    String? notes,
    ExertionLevel? exertionLevel,
  });

  /// Corrects the core fields of an already-logged attack (detail screen).
  /// The weather snapshot is untouched — it belongs to [startedAt].
  Future<void> updateCore(
    String id, {
    required int intensity,
    required HeadLocation location,
    String? medicationName,
  });

  /// Removes one attack; its weather snapshot goes with it via cascade.
  Future<void> deleteById(String id);

  /// GDPR wipe.
  Future<void> deleteAll();
}
