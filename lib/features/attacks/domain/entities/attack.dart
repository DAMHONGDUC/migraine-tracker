import 'package:meta/meta.dart';

import '../../../weather/domain/entities/weather_snapshot.dart';
import '../enums/aura_type.dart';
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
    this.aura,
    this.symptoms = const [],
    this.triggers = const [],
    this.notes,
    this.exertionLevel,
    this.medicationEffect,
    DateTime? endedAt,
    this.weather,
    this.steps,
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

  /// Aura kinds reported for this attack.
  ///
  /// Null is "never asked"; an EMPTY list is the user answering "no aura".
  /// The two are different facts — migraine with aura and without it are
  /// different diagnoses — so unlike [endedAt] they are not collapsed.
  final List<AuraType>? aura;

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

  /// Steps taken that day up to the moment the attack was logged, or null
  /// when Apple Health had nothing to give — access refused, no samples, or
  /// not iOS.
  ///
  /// **The day so far, not the whole day**, which is the same shape as
  /// [weather]: a reading taken at the time, not a figure the day settles on
  /// later. What a doctor wants beside an attack is how much the person had
  /// moved *before* it, and a total that keeps climbing after the attack
  /// answers a different question.
  ///
  /// Null and zero are different answers and both are real: zero is a day
  /// spent still, null is a day Health would not talk about.
  final int? steps;

  /// How long the attack lasted, or null while [endedAt] is unset.
  ///
  /// The 4–72h band is what separates a migraine from a tension headache, so
  /// this is the first thing a neurologist asks and the report could not
  /// answer before.
  Duration? get duration => endedAt?.difference(startedAt);

  Attack copyWith({WeatherSnapshot? weather, int? steps}) => Attack(
    id: id,
    startedAt: startedAt,
    intensity: intensity,
    regions: regions,
    aura: aura,
    medicationName: medicationName,
    symptoms: symptoms,
    triggers: triggers,
    notes: notes,
    exertionLevel: exertionLevel,
    medicationEffect: medicationEffect,
    endedAt: endedAt,
    weather: weather ?? this.weather,
    steps: steps ?? this.steps,
  );
}
