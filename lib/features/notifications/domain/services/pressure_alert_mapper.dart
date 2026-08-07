import '../entities/app_notification.dart';
import '../enums/notification_type.dart';

/// Turns the `data` payload of a pressure-alert push into a list row.
///
/// Pure, so the awkward part of push handling — what the message means — is
/// testable without a device, a token or a live Firebase.
///
/// The text is deliberately NOT read off the message: the backend writes it
/// in English whatever language the user picked, so only the numbers travel
/// and the list renders its own strings (hard rule 6).
final class PressureAlertMapper {
  const PressureAlertMapper._();

  /// The value the backend sets on `type`, so a future message of some
  /// other type is not mistaken for this one.
  static const String typeValue = 'pressureAlert';

  /// Null when the message is not a pressure alert, or is missing the two
  /// fields the row cannot be built without. Returning null rather than
  /// throwing is deliberate: a push arrives from outside the app, and a
  /// malformed one must be ignored, not crash a handler.
  static AppNotification? fromData(Map<String, dynamic> data) {
    if (data['type'] != typeValue) return null;

    final Object? eventId = data['eventId'];
    final Object? at = data['at'];

    if (eventId is! String || eventId.isEmpty) return null;
    final DateTime? occurredAt = at is String ? DateTime.tryParse(at) : null;
    if (occurredAt == null) return null;

    return AppNotification(
      // Keyed by the event the backend already dedupes on, so the foreground
      // handler and the launch reconcile land on one row rather than two.
      id: AppNotification.pressureAlertId(eventId),
      type: NotificationType.pressureAlert,
      occurredAt: occurredAt.toUtc(),
      pressureDropHpa: _drop(data['dropHpa']),
    );
  }

  /// The row survives a missing or unparseable drop — the sheet leaves the
  /// reading out rather than printing a number the forecast never gave.
  static double? _drop(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}
