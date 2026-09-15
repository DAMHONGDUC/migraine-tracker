import 'dart:convert';

import '../../../../core/utils/date_time_utils.dart';
import '../../../daily_log/domain/entities/daily_log.dart';
import '../../../daily_log/domain/enums/daily_factor.dart';
import 'sync_payload_codec.dart';

/// DailyLog ↔ the JSON that gets encrypted. Sleep, stress and every factor are health data, so they only leave the device inside a payload.
class DailyLogPayloadCodec implements SyncPayloadCodec<DailyLog> {
  const DailyLogPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(DailyLog value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'sleepQuality': value.sleepQuality,
    'stressLevel': value.stressLevel,
    'factors': <String>[for (final DailyFactor f in value.factors) f.name],
    'steps': value.steps,
  });

  /// [id] is the day itself (`yyyy-MM-dd`), which is why the payload never carries the date — see `DailyLogs`.
  @override
  DailyLog decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('daily log payload is not an object');
    }
    final Object? version = decoded[_versionKey];
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported daily log payload version $version');
    }
    final Object? factors = decoded['factors'];

    return DailyLog(
      day: DateTimeUtils.dayFromKey(id),
      sleepQuality: _rating(decoded['sleepQuality']),
      stressLevel: _rating(decoded['stressLevel']),
      factors: factors is List<dynamic>
          ? _factors(factors)
          : const <DailyFactor>[],
      steps: decoded['steps'] is int ? decoded['steps'] as int : null,
    );
  }

  /// Out-of-range reads as unanswered rather than throwing: one bad field must not cost the whole day's row.
  int? _rating(Object? value) =>
      value is int && value >= 1 && value <= 5 ? value : null;

  /// A factor this build has never heard of is dropped, so a newer device's day still opens here.
  List<DailyFactor> _factors(List<dynamic> names) => <DailyFactor>[
    for (final dynamic name in names)
      if (DailyFactor.values.asNameMap()[name] case final DailyFactor factor)
        factor,
  ];
}
