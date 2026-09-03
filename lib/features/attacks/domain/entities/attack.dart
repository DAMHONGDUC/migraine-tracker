import 'package:meta/meta.dart';

import '../../../weather/domain/entities/weather_snapshot.dart';
import '../enums/aura_type.dart';
import '../enums/exertion_level.dart';
import '../enums/head_region.dart';
import '../enums/medication_effect.dart';

/// A single migraine attack.
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
    DateTime? medicationTakenAt,
    DateTime? reliefAt,
    DateTime? endedAt,
    this.weather,
    this.steps,
  }) : startedAt = startedAt.toUtc(),
       medicationTakenAt = medicationTakenAt?.toUtc(),
       reliefAt = reliefAt?.toUtc(),
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
  final List<AuraType>? aura;

  /// Every area the user tapped, never empty.
  final List<HeadRegion> regions;

  final String? medicationName;
  final List<String> symptoms;
  final List<String> triggers;
  final String? notes;
  final ExertionLevel? exertionLevel;

  /// Whether [medicationName] helped, once the user has said.
  final MedicationEffect? medicationEffect;

  /// When the medication was swallowed, UTC. Null is "never said", which also covers every attack where nothing was taken.
  final DateTime? medicationTakenAt;

  /// When the pain eased, UTC. Recorded on its own because relief and the attack ending are different moments — the pain can fade hours before the day does.
  final DateTime? reliefAt;

  /// When the attack stopped, in UTC.
  final DateTime? endedAt;

  final WeatherSnapshot? weather;

  /// Steps taken that day up to the moment the attack was logged, or null when Apple Health had nothing to give — access refused, no samples, or not iOS.
  final int? steps;

  /// How long the attack lasted, or null while [endedAt] is unset.
  Duration? get duration => endedAt?.difference(startedAt);

  /// How long the medication took to work, or null until both halves are answered. Negative is impossible — the sheet will not offer it.
  Duration? get timeToRelief =>
      medicationTakenAt == null || reliefAt == null
      ? null
      : reliefAt!.difference(medicationTakenAt!);

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
    medicationTakenAt: medicationTakenAt,
    reliefAt: reliefAt,
    endedAt: endedAt,
    weather: weather ?? this.weather,
    steps: steps ?? this.steps,
  );
}
