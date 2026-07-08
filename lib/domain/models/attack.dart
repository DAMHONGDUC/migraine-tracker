import 'package:meta/meta.dart';

import 'head_location.dart';
import 'weather_snapshot.dart';

/// A single migraine attack. The three required fields ([intensity],
/// [location], [medicationName]) mirror the 3-tap log flow; everything else
/// is optional detail. [weather] is null while offline and backfilled later.
@immutable
class Attack {
  Attack({
    required this.id,
    required DateTime startedAt,
    required this.intensity,
    required this.location,
    this.medicationName,
    this.symptoms = const [],
    this.triggers = const [],
    this.notes,
    this.weather,
  }) : startedAt = startedAt.toUtc(),
       assert(
         intensity >= 1 && intensity <= 10,
         'intensity must be within 1..10',
       );

  final String id;

  /// Stored in UTC; render in the user's local timezone at the UI layer.
  final DateTime startedAt;

  /// Pain intensity, 1–10.
  final int intensity;

  final HeadLocation location;
  final String? medicationName;
  final List<String> symptoms;
  final List<String> triggers;
  final String? notes;
  final WeatherSnapshot? weather;

  Attack copyWith({WeatherSnapshot? weather}) => Attack(
    id: id,
    startedAt: startedAt,
    intensity: intensity,
    location: location,
    medicationName: medicationName,
    symptoms: symptoms,
    triggers: triggers,
    notes: notes,
    weather: weather ?? this.weather,
  );
}
