import 'dart:convert';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../weather/domain/entities/weather_snapshot.dart';
import 'sync_payload_codec.dart';

/// Turns an attack into the JSON that gets encrypted, and back.
///
/// The weather snapshot travels inside the attack rather than as a record of
/// its own: it is meaningless without the attack, and one document per attack
/// keeps a partial sync from ever splitting the two apart.
class AttackPayloadCodec implements SyncPayloadCodec<Attack> {
  const AttackPayloadCodec();

  /// Bumped only when the shape changes incompatibly. Written on every
  /// payload so an older build can tell "I cannot read this" from "this is
  /// corrupt", instead of guessing.
  ///
  /// Adding an optional field is NOT a bump: [decode] ignores keys it does
  /// not know, so an older build keeps reading the newer payload. Bump only
  /// when an old build would misread the result — and expect it to skip every
  /// record written by the new one from then on.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(Attack attack) {
    final WeatherSnapshot? weather = attack.weather;

    return jsonEncode(<String, dynamic>{
      _versionKey: schemaVersion,
      'startedAt': attack.startedAt.toUtc().toIso8601String(),
      'intensity': attack.intensity,
      'location': attack.location.name,
      'medicationName': attack.medicationName,
      'symptoms': attack.symptoms,
      'triggers': attack.triggers,
      'notes': attack.notes,
      'exertionLevel': attack.exertionLevel?.name,
      'endedAt': attack.endedAt?.toUtc().toIso8601String(),
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

  /// Throws [FormatException] on anything it cannot faithfully rebuild — a
  /// half-read attack is worse than a skipped one, since it would overwrite
  /// the good local copy.
  @override
  Attack decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('attack payload is not an object');
    }
    final Object? version = decoded[_versionKey];

    // Only the future is unreadable. Refusing anything that merely differs
    // would mean the first bump orphaned every record already uploaded — the
    // new build would reject the user's entire history.
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported attack payload version $version');
    }
    final Object? weather = decoded['weather'];

    return Attack(
      id: id,
      startedAt: _date(decoded['startedAt'], 'startedAt'),
      intensity: _int(decoded['intensity'], 'intensity'),
      location: _enum(decoded['location'], HeadLocation.values, 'location'),
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
      // Optional and additive, so schemaVersion stays 1: a build that
      // predates this reads the payload and simply drops the field.
      endedAt: _dateOrNull(decoded['endedAt']),
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

  static double? _doubleOrNull(Object? value) =>
      value is num ? value.toDouble() : null;

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const <String>[];

  static T _enum<T extends Enum>(Object? value, List<T> values, String field) {
    for (final T candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw FormatException('$field has unknown value $value');
  }
}
