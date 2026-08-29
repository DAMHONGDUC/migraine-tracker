import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/sync/domain/services/app_notification_payload_codec.dart';

void main() {
  const AppNotificationPayloadCodec codec = AppNotificationPayloadCodec();

  test('a reminder notification survives a round trip', () {
    final AppNotification value = AppNotification(
      id: 'rem:r1:29000000',
      type: NotificationType.medicationReminder,
      occurredAt: DateTime.utc(2026, 8, 7, 9),
      readAt: DateTime.utc(2026, 8, 7, 10),
      medicationId: 'm1',
      reminderId: 'r1',
    );

    final AppNotification back = codec.decode(
      codec.encode(value),
      id: value.id,
    );

    expect(back.id, value.id);
    expect(back.type, NotificationType.medicationReminder);
    expect(back.occurredAt, value.occurredAt);
    expect(back.readAt, value.readAt);
    expect(back.medicationId, 'm1');
    expect(back.reminderId, 'r1');
    expect(back.pressureDropHpa, isNull);
  });

  test('a pressure alert survives a round trip', () {
    final AppNotification value = AppNotification(
      id: 'pa:evt-1',
      type: NotificationType.pressureAlert,
      occurredAt: DateTime.utc(2026, 8, 7, 6),
      pressureDropHpa: -7.5,
    );

    final AppNotification back = codec.decode(
      codec.encode(value),
      id: value.id,
    );

    expect(back.type, NotificationType.pressureAlert);
    expect(back.pressureDropHpa, -7.5);
    expect(back.readAt, isNull);
    expect(back.medicationId, isNull);
  });

  test('the id is never written into the payload', () {
    final Map<String, dynamic> json =
        jsonDecode(
              codec.encode(
                AppNotification(
                  id: 'rem:r1:29000000',
                  type: NotificationType.medicationReminder,
                  occurredAt: DateTime.utc(2026, 8, 7, 9),
                ),
              ),
            )
            as Map<String, dynamic>;

    // The document id is the record's identity; a second copy inside could only ever disagree with it.
    expect(json.containsKey('id'), isFalse);
  });

  test('an unknown kind is refused, not guessed at', () {
    final String json = jsonEncode(<String, dynamic>{
      'v': 1,
      'type': 'somethingNewer',
      'occurredAt': DateTime.utc(2026, 8, 7).toIso8601String(),
    });

    // Counted unreadable and skipped by the sync, which shows one row fewer rather than a row labelled as the wrong thing.
    expect(() => codec.decode(json, id: 'x'), throwsFormatException);
  });

  test('a newer payload version is refused, an older one is not', () {
    String payload(int version) => jsonEncode(<String, dynamic>{
      'v': version,
      'type': 'pressureAlert',
      'occurredAt': DateTime.utc(2026, 8, 7).toIso8601String(),
    });

    expect(
      () => codec.decode(
        payload(AppNotificationPayloadCodec.schemaVersion + 1),
        id: 'x',
      ),
      throwsFormatException,
    );
    expect(
      codec
          .decode(payload(AppNotificationPayloadCodec.schemaVersion), id: 'x')
          .type,
      NotificationType.pressureAlert,
    );
  });

  test(
    'an unrecognised field is ignored, so an added one stays compatible',
    () {
      final String json = jsonEncode(<String, dynamic>{
        'v': 1,
        'type': 'pressureAlert',
        'occurredAt': DateTime.utc(2026, 8, 7).toIso8601String(),
        'somethingAddedLater': 'whatever',
      });

      expect(
        codec.decode(json, id: 'pa:1').type,
        NotificationType.pressureAlert,
      );
    },
  );

  test('a payload with no usable time is refused', () {
    final String json = jsonEncode(<String, dynamic>{
      'v': 1,
      'type': 'pressureAlert',
      'occurredAt': 'not a date',
    });

    expect(() => codec.decode(json, id: 'x'), throwsFormatException);
  });
}
