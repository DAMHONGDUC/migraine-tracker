import 'dart:convert';

import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/enums/notification_type.dart';
import 'sync_payload_codec.dart';

/// Notification ↔ the JSON that gets encrypted.
class AppNotificationPayloadCodec implements SyncPayloadCodec<AppNotification> {
  const AppNotificationPayloadCodec();

  /// See `AttackPayloadCodec.schemaVersion` for when this is bumped, and when it deliberately is not.
  static const int schemaVersion = 1;

  static const String _versionKey = 'v';

  @override
  String encode(AppNotification value) => jsonEncode(<String, dynamic>{
    _versionKey: schemaVersion,
    'type': value.type.name,
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
    final Object? type = decoded['type'];
    final Object? occurredAt = decoded['occurredAt'];
    final DateTime? at = occurredAt is String
        ? DateTime.tryParse(occurredAt)
        : null;

    // A type this build has never heard of is refused, not guessed at.
    final NotificationType? parsed = _typeByName(type);
    if (parsed == null) {
      throw FormatException('unknown notification type $type');
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
      type: parsed,
      occurredAt: at.toUtc(),
      readAt: readAt is String ? DateTime.tryParse(readAt)?.toUtc() : null,
      medicationId: medicationId is String ? medicationId : null,
      reminderId: reminderId is String ? reminderId : null,
      pressureDropHpa: drop is num ? drop.toDouble() : null,
    );
  }

  NotificationType? _typeByName(Object? name) {
    for (final NotificationType type in NotificationType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
