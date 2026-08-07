import 'package:meta/meta.dart';

import '../enums/notification_type.dart';

/// One notification the user was shown, as the list renders it.
///
/// Named `AppNotification`, never `Notification`: Flutter already owns that
/// name for the widget-tree message class, and a bare import would shadow it.
///
/// **No title or body is stored.** The row carries the facts — which
/// medication, how far the pressure fell — and the strings are rendered from
/// ARB at display time, so changing the app's language changes the list with
/// it. A stored string would freeze whatever locale was active when the
/// notification arrived, and the pressure alert's own text arrives from the
/// server in English regardless.
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

  /// Derived, never random — [reminderOccurrenceId] and [pressureAlertId]
  /// build it. Two devices computing the same occurrence arrive at the same
  /// id, which is what makes every writer idempotent and lets the list match
  /// across devices without any of them agreeing first.
  final String id;

  final NotificationType type;

  /// When the notification actually fired, in UTC.
  final DateTime occurredAt;

  /// Null while unread. A timestamp rather than a flag so two devices that
  /// both read it settle on one answer the same way every other synced field
  /// does.
  final DateTime? readAt;

  /// The medication this reminder was for. A plain id with no foreign key:
  /// deleting a medication must not delete the history of being reminded
  /// about it, and the detail screen already handles a medication that is
  /// gone.
  final String? medicationId;

  /// The reminder that produced this occurrence — also no foreign key, and
  /// for the same reason.
  final String? reminderId;

  /// How far pressure was forecast to fall, for a [NotificationType.pressureAlert].
  final double? pressureDropHpa;

  bool get isRead => readAt != null;

  /// The id every device derives for one reminder firing at one minute.
  ///
  /// Minute resolution because that is what a reminder is stored at
  /// (`minuteOfDay`); seconds would let two devices disagree over the same
  /// occurrence.
  static String reminderOccurrenceId(String reminderId, DateTime occurredAt) =>
      'rem:$reminderId:${occurredAt.toUtc().millisecondsSinceEpoch ~/ 60000}';

  /// The id for one pressure alert, keyed by the event the backend already
  /// dedupes on — so the foreground handler, a pull of the same alert, and
  /// any background handler added later all land on one row.
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
