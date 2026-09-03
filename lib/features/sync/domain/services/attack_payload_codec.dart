import 'dart:convert';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import 'sync_payload_codec.dart';

/// Turns an attack into the JSON that gets encrypted, and back.
class AttackPayloadCodec implements SyncPayloadCodec<Attack> {
  const AttackPayloadCodec();

  /// Bumped only when the shape changes incompatibly.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(Attack attack) {
    final WeatherSnapshot? weather = attack.weather;

    return jsonEncode(<String, dynamic>{
      _versionKey: schemaVersion,
      'startedAt': attack.startedAt.toUtc().toIso8601String(),
      'intensity': attack.intensity,
      'regions': <String>[for (final HeadRegion r in attack.regions) r.name],
      // Written for readers, never read back here.
      'location': HeadLocation.coarsest(attack.regions).name,
      'aura': attack.aura == null
          ? null
          : <String>[for (final AuraType a in attack.aura!) a.name],
      'medicationName': attack.medicationName,
      'steps': attack.steps,
      'symptoms': attack.symptoms,
      'triggers': attack.triggers,
      'notes': attack.notes,
      'exertionLevel': attack.exertionLevel?.name,
      'endedAt': attack.endedAt?.toUtc().toIso8601String(),
      // Optional and additive, like endedAt above: schemaVersion stays 1.
      'medicationTakenAt': attack.medicationTakenAt?.toUtc().toIso8601String(),
      'reliefAt': attack.reliefAt?.toUtc().toIso8601String(),
      'medicationEffect': attack.medicationEffect?.name,
      'weather': weather == null
          ? null
          : <String, dynamic>{
              'capturedAt': weather.capturedAt.toUtc().toIso8601String(),
              'pressureHpa': weather.pressureHpa,
              'pressureDelta24hHpa': weather.pressureDelta24hHpa,
              'humidityPercent': weather.humidityPercent,
              'temperatureCelsius': weather.temperatureCelsius,
            },
    });
  }

  /// Throws [FormatException] on anything it cannot faithfully rebuild.
  @override
  Attack decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('attack payload is not an object');
    }
    final Object? version = decoded[_versionKey];

    // Only the future is unreadable.
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported attack payload version $version');
    }
    final Object? weather = decoded['weather'];

    return Attack(
      id: id,
      startedAt: _date(decoded['startedAt'], 'startedAt'),
      intensity: _int(decoded['intensity'], 'intensity'),
    // Fall back to the legacy coarse location without guessing finer regions.
      regions: decoded['regions'] == null
          ? _enum(decoded['location'], HeadLocation.values, 'location').regions
          : _regions(decoded['regions']),
      // Optional and additive, so schemaVersion stays 1.
      aura: _aura(decoded['aura']),
      medicationName: _stringOrNull(decoded['medicationName']),
      symptoms: _strings(decoded['symptoms']),
      triggers: _strings(decoded['triggers']),
      notes: _stringOrNull(decoded['notes']),
      exertionLevel: decoded['exertionLevel'] == null
          ? null
          : _enum(
              decoded['exertionLevel'],
              ExertionLevel.values,
              'exertionLevel',
            ),
      // Optional and additive, so schemaVersion stays 1: a build that predates this reads the payload and simply drops the field.
      endedAt: _dateOrNull(decoded['endedAt']),
      medicationTakenAt: _dateOrNull(decoded['medicationTakenAt']),
      reliefAt: _dateOrNull(decoded['reliefAt']),
      steps: _intOrNull(decoded['steps']),
      medicationEffect: decoded['medicationEffect'] == null
          ? null
          : _enum(
              decoded['medicationEffect'],
              MedicationEffect.values,
              'medicationEffect',
            ),
      weather: weather == null
          ? null
          : _weather(weather as Map<String, dynamic>),
    );
  }

  static WeatherSnapshot _weather(Map<String, dynamic> json) => WeatherSnapshot(
    capturedAt: _date(json['capturedAt'], 'weather.capturedAt'),
    pressureHpa: _double(json['pressureHpa'], 'weather.pressureHpa'),
    pressureDelta24hHpa: _double(
      json['pressureDelta24hHpa'],
      'weather.pressureDelta24hHpa',
    ),
    humidityPercent: _doubleOrNull(json['humidityPercent']),
    temperatureCelsius: _doubleOrNull(json['temperatureCelsius']),
  );

  static DateTime _date(Object? value, String field) {
    if (value is! String) throw FormatException('$field is not a date');
    return DateTime.parse(value).toUtc();
  }

  static int _int(Object? value, String field) {
    if (value is! int) throw FormatException('$field is not an int');
    return value;
  }

  static double _double(Object? value, String field) {
    if (value is! num) throw FormatException('$field is not a number');
    return value.toDouble();
  }

  static DateTime? _dateOrNull(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static int? _intOrNull(Object? value) => value is int ? value : null;

  static double? _doubleOrNull(Object? value) =>
      value is num ? value.toDouble() : null;

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const <String>[];

  /// Throws when the list holds no region the app knows: an attack with no location cannot be rebuilt faithfully, and the entity forbids it.
  static List<AuraType>? _aura(Object? value) {
    if (value is! List) return null;

    return <AuraType>[
      for (final Object? name in value)
        if (AuraType.values.asNameMap()[name] case final AuraType aura) aura,
    ];
  }

  static List<HeadRegion> _regions(Object? value) {
    if (value is! List) {
      throw FormatException('regions is not a list: $value');
    }
    final List<HeadRegion> regions = <HeadRegion>[
      for (final Object? name in value)
        if (HeadRegion.values.asNameMap()[name] case final HeadRegion region)
          region,
    ];

    if (regions.isEmpty) {
      throw FormatException('regions holds no known region: $value');
    }

    return regions;
  }

  static T _enum<T extends Enum>(Object? value, List<T> values, String field) {
    for (final T candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw FormatException('$field has unknown value $value');
  }
}
