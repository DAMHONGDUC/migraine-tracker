import 'dart:convert';

import '../../../medications/domain/entities/medication_reminder.dart';
import 'sync_payload_codec.dart';

/// Reminder ↔ the JSON that gets encrypted.
///
/// `medicationId` travels because a reminder is meaningless without the
/// medication it belongs to; the receiving device holds the reminder back
/// until that medication has arrived.
class MedicationReminderPayloadCodec
    implements SyncPayloadCodec<MedicationReminder> {
  const MedicationReminderPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when
  /// it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  /// Minutes past midnight, so the last valid value is 23:59.
  static const int _maxMinuteOfDay = 1439;

  @override
  String encode(MedicationReminder value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'medicationId': value.medicationId,
    'minuteOfDay': value.minuteOfDay,
    'enabled': value.enabled,
  });

  @override
  MedicationReminder decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('reminder payload is not an object');
    }
    final Object? version = decoded[_versionKey];
    if (version is! int || version > schemaVersion) {
      throw FormatException('unsupported reminder payload version $version');
    }
    final Object? medicationId = decoded['medicationId'];
    final Object? minuteOfDay = decoded['minuteOfDay'];

    if (medicationId is! String || medicationId.isEmpty) {
      throw const FormatException('reminder payload has no medication');
    }
    // A time outside the day would schedule a notification that never fires,
    // or crash the scheduler — refuse it rather than store it.
    if (minuteOfDay is! int ||
        minuteOfDay < 0 ||
        minuteOfDay > _maxMinuteOfDay) {
      throw FormatException('reminder payload has a bad time $minuteOfDay');
    }

    return MedicationReminder(
      id: id,
      medicationId: medicationId,
      minuteOfDay: minuteOfDay,
      enabled: decoded['enabled'] != false,
    );
  }
}
