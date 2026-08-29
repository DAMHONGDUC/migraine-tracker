import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/attack.dart';
import '../enums/aura_type.dart';
import '../enums/exertion_level.dart';
import '../enums/head_region.dart';
import '../enums/medication_effect.dart';

/// Contract for attack storage.
abstract interface class AttackRepository {
  /// All attacks, newest first, with their weather snapshot when present.
  Stream<List<Attack>> watchAll();

  /// One-shot read of everything [watchAll] would emit (e.g. for export).
  Future<List<Attack>> getAll();

  /// A single attack (with its weather), or null if it no longer exists — e.g. deleted from another screen while the detail view was open.
  Stream<Attack?> watchById(String id);

  /// Inserts the attack and, if already available, its weather snapshot. Works fully offline: [Attack.weather] may simply be null.
  Future<void> insert(Attack attack);

  /// Backfills the weather snapshot for an attack logged offline.
  Future<void> attachWeather(String attackId, WeatherSnapshot weather);

  /// Records the day's step count on an already-saved attack.
  Future<void> attachSteps(String attackId, int steps);

  /// Attacks still waiting for a weather snapshot (offline backfill queue).
  Future<List<Attack>> attacksMissingWeather();

  /// Fills in the optional detail fields added after the 3-tap flow saved.
  Future<void> updateDetails(
    String id, {
    required List<String> symptoms,
    required List<String> triggers,
    String? notes,
  });

  /// Updates exertion independently because it is part of the main log flow.
  Future<void> updateExertion(String id, ExertionLevel? exertionLevel);

  /// When the attack stopped, or null to take the answer back.
  Future<void> updateEndedAt(String id, DateTime? endedAt);

  /// Whether the medication helped, or null to take the answer back. Its own method for the same reason [updateExertion] is.
  Future<void> updateMedicationEffect(String id, MedicationEffect? effect);

  /// Records the aura kinds for an attack, after the fact.
  Future<void> updateAura(String id, List<AuraType>? aura);

  /// Corrects the core fields of an already-logged attack (detail screen). The weather snapshot is untouched — it belongs to [startedAt].
  Future<void> updateCore(
    String id, {
    required int intensity,
    required List<HeadRegion> regions,
    String? medicationName,
  });

  /// Removes one attack; its weather snapshot goes with it via cascade.
  Future<void> deleteById(String id);

  /// GDPR wipe.
  Future<void> deleteAll();
}
