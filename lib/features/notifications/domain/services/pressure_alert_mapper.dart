import '../entities/app_notification.dart';
import '../enums/notification_type.dart';

/// Turns the `data` payload of a pressure-alert push into a list row.
final class PressureAlertMapper {
  const PressureAlertMapper._();

  /// The value the backend sets on `type`, so a future message of some other type is not mistaken for this one.
  static const String typeValue = 'pressureAlert';

  /// Null when the message is not a pressure alert, or is missing the two fields the row cannot be built without.
  static AppNotification? fromData(Map<String, dynamic> data) {
    if (data['type'] != typeValue) return null;

    final Object? at = data['at'];

    return fromRecord(
      eventId: data['eventId'],
      occurredAt: at is String ? DateTime.tryParse(at) : null,
      dropHpa: data['dropHpa'],
    );
  }

  /// The same row from the `lastAlert*` fields on `users/{uid}`, which the cron writes after every push.
  static AppNotification? fromRecord({
    required Object? eventId,
    required DateTime? occurredAt,
    Object? dropHpa,
  }) {
    if (eventId is! String || eventId.isEmpty) return null;
    if (occurredAt == null) return null;

    return AppNotification(
      // Keyed by the event the backend already dedupes on, so the foreground handler, a reconcile and a pull of the same alert land on one row.
      id: AppNotification.pressureAlertId(eventId),
      type: NotificationType.pressureAlert,
      occurredAt: occurredAt.toUtc(),
      pressureDropHpa: _drop(dropHpa),
    );
  }

  /// The row survives a missing or unparseable drop — the detail screen leaves the reading out rather than printing a number the forecast never gave.
  static double? _drop(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}
