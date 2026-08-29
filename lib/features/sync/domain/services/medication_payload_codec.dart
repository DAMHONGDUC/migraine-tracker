import 'dart:convert';

import '../../../medications/domain/entities/medication.dart';
import 'sync_payload_codec.dart';

/// Medication ↔ the JSON that gets encrypted. The name is health data (what someone takes), so it only ever leaves the device inside a payload.
class MedicationPayloadCodec implements SyncPayloadCodec<Medication> {
  const MedicationPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(Medication value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'name': value.name,
    'createdAt': value.createdAt?.toUtc().toIso8601String(),
  });

  @override
  Medication decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('medication payload is not an object');
    }
    final Object? version = decoded[_versionKey];
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported medication payload version $version');
    }
    final Object? name = decoded['name'];
    if (name is! String || name.isEmpty) {
      throw const FormatException('medication payload has no name');
    }
    final Object? createdAt = decoded['createdAt'];

    return Medication(
      id: id,
      name: name,
      // Null stays null: a medication saved before v3 has no recorded date, and inventing one would list it under "added this week".
      createdAt: createdAt is String ? DateTime.parse(createdAt).toUtc() : null,
    );
  }
}
