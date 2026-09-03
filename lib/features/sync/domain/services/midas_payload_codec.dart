import 'dart:convert';

import '../../../insights/domain/entities/midas_score.dart';
import 'sync_payload_codec.dart';

/// MidasEntry ↔ the JSON that gets encrypted. Days lost to migraine is health data, so it only leaves the device inside a payload.
class MidasPayloadCodec implements SyncPayloadCodec<MidasEntry> {
  const MidasPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(MidasEntry value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'takenAt': value.takenAt.toUtc().toIso8601String(),
    'missedWorkDays': value.missedWorkDays,
    'reducedWorkDays': value.reducedWorkDays,
    'missedHouseholdDays': value.missedHouseholdDays,
    'reducedHouseholdDays': value.reducedHouseholdDays,
    'missedSocialDays': value.missedSocialDays,
  });

  @override
  MidasEntry decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('midas payload is not an object');
    }
    final Object? version = decoded[_versionKey];
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported midas payload version $version');
    }
    final Object? takenAt = decoded['takenAt'];
    if (takenAt is! String) {
      throw const FormatException('midas payload has no takenAt');
    }

    return MidasEntry(
      id: id,
      takenAt: DateTime.parse(takenAt).toUtc(),
      missedWorkDays: _days(decoded['missedWorkDays']),
      reducedWorkDays: _days(decoded['reducedWorkDays']),
      missedHouseholdDays: _days(decoded['missedHouseholdDays']),
      reducedHouseholdDays: _days(decoded['reducedHouseholdDays']),
      missedSocialDays: _days(decoded['missedSocialDays']),
    );
  }

  /// A missing or impossible count reads as zero rather than throwing: one bad field must not cost the whole questionnaire.
  int _days(Object? value) => value is int && value >= 0 ? value : 0;
}
