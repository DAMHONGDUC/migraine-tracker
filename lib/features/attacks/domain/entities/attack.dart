import 'package:meta/meta.dart';

import '../../../weather/domain/entities/weather_snapshot.dart';
import '../enums/exertion_level.dart';
import '../enums/head_region.dart';
import '../enums/medication_effect.dart';

/// A single migraine attack. The three required fields ([intensity],
/// [regions], [medicationName]) mirror the 3-tap log flow; everything else
/// is optional detail. [weather] is null while offline and backfilled later.
@immutable
class Attack {
  Attack({
    required this.id,
    required DateTime startedAt,
    required this.intensity,
    required this.regions,
    this.medicationName,
    this.symptoms = const [],
    this.triggers = const [],
    this.notes,
    this.exertionLevel,
    this.medicationEffect,
    DateTime? endedAt,
    this.weather,
  }) : startedAt = startedAt.toUtc(),
       endedAt = endedAt?.toUtc(),
       assert(
         intensity >= 1 && intensity <= 10,
         'intensity must be within 1..10',
       ),
       assert(
         regions.isNotEmpty,
         'an attack must name at least one region — the location step is the '
         'one step of the flow that waits for a pick',
       ),
       assert(
         endedAt == null || !endedAt.toUtc().isBefore(startedAt.toUtc()),
         'an attack cannot end before it started',
       );

  final String id;

  /// Stored in UTC; render in the user's local timezone at the UI layer.
  final DateTime startedAt;

  /// Pain intensity, 1–10.
  final int intensity;

  /// Every area the user tapped, never empty. A set in meaning but a list in
  /// storage, kept in [HeadRegion] order so two attacks naming the same areas
  /// serialize identically and the sync codec's comparison stays honest.
  final List<HeadRegion> regions;

  final String? medicationName;
  final List<String> symptoms;
  final List<String> triggers;
  final String? notes;
  final ExertionLevel? exertionLevel;

  /// Whether [medicationName] helped, once the user has said. Null is "not
  /// answered", which is also every attack where nothing was taken — the
  /// medication row is what tells the two apart, so nothing here needs a
  /// fourth state.
  final MedicationEffect? medicationEffect;

  /// When the attack stopped, in UTC. Null means "still going, or never
  /// said" — the two are deliberately one state, because the app cannot tell
  /// them apart and guessing either way would put a number in the doctor
  /// report that the user never gave.
  ///
  /// Never asked during the log flow: at the moment an attack is logged
  /// nobody knows how long it will last, and the three taps are sacred
  /// (hard rule 5). It is recorded afterwards, from the detail screen.
  final DateTime? endedAt;

  final WeatherSnapshot? weather;

  /// How long the attack lasted, or null while [endedAt] is unset.
  ///
  /// The 4–72h band is what separates a migraine from a tension headache, so
  /// this is the first thing a neurologist asks and the report could not
  /// answer before.
  Duration? get duration => endedAt?.difference(startedAt);

  Attack copyWith({WeatherSnapshot? weather}) => Attack(
    id: id,
    startedAt: startedAt,
    intensity: intensity,
    regions: regions,
    medicationName: medicationName,
    symptoms: symptoms,
    triggers: triggers,
    notes: notes,
    exertionLevel: exertionLevel,
    medicationEffect: medicationEffect,
    endedAt: endedAt,
    weather: weather ?? this.weather,
  );
}
