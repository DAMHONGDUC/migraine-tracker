import 'package:meta/meta.dart';

import '../enums/notification_type.dart';

/// One notification the user was shown, as the list renders it.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.readAt,
    this.medicationId,
    this.reminderId,
    this.pressureDropHpa,
  });

  /// Derived, never random — [reminderOccurrenceId] and [pressureAlertId] build it.
  final String id;

  final NotificationType type;

  /// When the notification actually fired, in UTC.
  final DateTime occurredAt;

  /// Null while unread. A timestamp rather than a flag so two devices that both read it settle on one answer the same way every other synced field does.
  final DateTime? readAt;

  /// The medication this reminder was for.
  final String? medicationId;

  /// The reminder that produced this occurrence — also no foreign key, and for the same reason.
  final String? reminderId;

  /// How far pressure was forecast to fall, for a [NotificationType.pressureAlert].
  final double? pressureDropHpa;

  bool get isRead => readAt != null;

  /// The id every device derives for one reminder firing at one minute.
  static String reminderOccurrenceId(String reminderId, DateTime occurredAt) =>
      'rem:$reminderId:${occurredAt.toUtc().millisecondsSinceEpoch ~/ 60000}';

  /// The id for one pressure alert, keyed by the event the backend already dedupes on.
  static String pressureAlertId(String eventId) => 'pa:$eventId';

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    occurredAt: occurredAt,
    readAt: readAt ?? this.readAt,
    medicationId: medicationId,
    reminderId: reminderId,
    pressureDropHpa: pressureDropHpa,
  );
}
