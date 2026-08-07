import 'dart:convert';

import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/enums/notification_kind.dart';
import 'sync_payload_codec.dart';

/// Notification ↔ the JSON that gets encrypted.
///
/// Everything but the id goes in the ciphertext, `medicationId` included: it
/// says which drug the user is reminded to take, which is a medication
/// schedule in all but name (hard rule 1).
///
/// The id itself never travels in the payload because it is derived from the
/// same facts on both sides — the document id IS the record's identity, and a
/// second copy inside could only disagree with it.
class AppNotificationPayloadCodec implements SyncPayloadCodec<AppNotification> {
  const AppNotificationPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when
  /// it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(AppNotification value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'kind': value.kind.name,
    'occurredAt': value.occurredAt.toUtc().toIso8601String(),
    'readAt': value.readAt?.toUtc().toIso8601String(),
    'medicationId': value.medicationId,
    'reminderId': value.reminderId,
    'pressureDropHpa': value.pressureDropHpa,
  });

  @override
  AppNotification decode(String json, {required String id}) {
    final Object? decoded = jsonDecode(json);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('notification payload is not an object');
    }
    final Object? version = decoded[_versionKey];
    if (version is! int || version > schemaVersion) {
      throw FormatException(
        'unsupported notification payload version $version',
      );
    }
    final Object? kind = decoded['kind'];
    final Object? occurredAt = decoded['occurredAt'];
    final DateTime? at = occurredAt is String
        ? DateTime.tryParse(occurredAt)
        : null;

    // A kind this build has never heard of is refused, not guessed at: the
    // sync counts it unreadable and moves on, which shows one row fewer
    // rather than a row labelled as the wrong thing.
    final NotificationKind? parsed = _kindByName(kind);
    if (parsed == null) {
      throw FormatException('unknown notification kind $kind');
    }
    if (at == null) {
      throw FormatException('notification payload has a bad time $occurredAt');
    }
    final Object? readAt = decoded['readAt'];
    final Object? medicationId = decoded['medicationId'];
    final Object? reminderId = decoded['reminderId'];
    final Object? drop = decoded['pressureDropHpa'];

    return AppNotification(
      id: id,
      kind: parsed,
      occurredAt: at.toUtc(),
      readAt: readAt is String ? DateTime.tryParse(readAt)?.toUtc() : null,
      medicationId: medicationId is String ? medicationId : null,
      reminderId: reminderId is String ? reminderId : null,
      pressureDropHpa: drop is num ? drop.toDouble() : null,
    );
  }

  NotificationKind? _kindByName(Object? name) {
    for (final NotificationKind kind in NotificationKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}
