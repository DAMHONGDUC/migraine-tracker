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
    // Optional field, so no version bump: an older build ignores keys it
    // does not know. It travels because the notification list bounds its
    // history by this, and every device has to agree where that starts.
    'createdAt': value.createdAt?.toUtc().toIso8601String(),
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

    final Object? createdAt = decoded['createdAt'];

    return MedicationReminder(
      id: id,
      medicationId: medicationId,
      minuteOfDay: minuteOfDay,
      enabled: decoded['enabled'] != false,
      // Absent from anything written before this field existed, and an
      // unparseable value is the same as absent: unknown, not invalid.
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
