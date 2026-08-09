import '../../../weather/domain/entities/weather_snapshot.dart';
import '../entities/attack.dart';
import '../enums/exertion_level.dart';
import '../enums/head_location.dart';
import '../enums/medication_effect.dart';

/// Contract for attack storage. Features depend on this, never on the Drift
/// implementation.
///
/// Deliberately knows nothing about sync: every mutation records that the row
/// changed, and `AttackSyncRepository` reads that separately. A decorator that
/// uploaded on write would put the network in front of the log flow, which
/// hard rule 4 forbids.
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
  });

  /// Exertion on its own, because it is no longer a "detail": it is a step of
  /// the log flow, and folding it into [updateDetails] would let a save from
  /// the details sheet blank an answer that sheet never showed.
  Future<void> updateExertion(String id, ExertionLevel? exertionLevel);

  /// When the attack stopped, or null to take the answer back. Its own method
  /// for the same reason [updateExertion] is: it is never shown by the details
  /// sheet, so a save from there must not be able to blank it.
  Future<void> updateEndedAt(String id, DateTime? endedAt);

  /// Whether the medication helped, or null to take the answer back. Its own
  /// method for the same reason [updateExertion] is.
  Future<void> updateMedicationEffect(String id, MedicationEffect? effect);

  /// Corrects the core fields of an already-logged attack (detail screen).
  /// The weather snapshot is untouched — it belongs to [startedAt].
  Future<void> updateCore(
    String id, {
    required int intensity,
    required HeadLocation location,
    String? medicationName,
  });

  /// Removes one attack; its weather snapshot goes with it via cascade. The
  /// row is really deleted — what is left behind is a tombstone holding only
  /// the id, so the deletion can still reach the user's other devices.
  Future<void> deleteById(String id);

  /// GDPR wipe.
  Future<void> deleteAll();
}
