import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/domain/services/pressure_alert_mapper.dart';

Map<String, dynamic> data({
  String type = 'pressureAlert',
  Object? eventId = 'evt-1',
  Object? at = '2026-08-07T06:00:00.000Z',
  Object? dropHpa = '-7.5',
}) => <String, dynamic>{
  'type': type,
  'eventId': ?eventId,
  'at': ?at,
  'dropHpa': ?dropHpa,
};

void main() {
  test('a well-formed alert becomes a row keyed by its event', () {
    final AppNotification? result = PressureAlertMapper.fromData(data());

    expect(result, isNotNull);
    expect(result!.type, NotificationType.pressureAlert);
    expect(result.id, 'pa:evt-1');
    expect(result.occurredAt, DateTime.utc(2026, 8, 7, 6));
    expect(result.pressureDropHpa, -7.5);
    expect(result.medicationId, isNull);
  });

  test('the id is what makes two handlers land on one row', () {
    // The foreground push and the launch reconcile see the same event.
    expect(
      PressureAlertMapper.fromData(data())!.id,
      PressureAlertMapper.fromData(data(dropHpa: -7.5))!.id,
    );
  });

  test('a message of another kind is not ours', () {
    expect(PressureAlertMapper.fromData(data(type: 'somethingElse')), isNull);
  });

  test('no event id and no time mean no row', () {
    expect(PressureAlertMapper.fromData(data(eventId: null)), isNull);
    expect(PressureAlertMapper.fromData(data(eventId: '')), isNull);
    expect(PressureAlertMapper.fromData(data(at: null)), isNull);
    expect(PressureAlertMapper.fromData(data(at: 'not a date')), isNull);
  });

  test('a missing drop still yields a row, without the reading', () {
    final AppNotification? result = PressureAlertMapper.fromData(
      data(dropHpa: null),
    );

    // The sheet leaves the number out rather than printing one the forecast never gave.
    expect(result, isNotNull);
    expect(result!.pressureDropHpa, isNull);
  });

  test('the drop is read whether it arrives as text or a number', () {
    expect(
      PressureAlertMapper.fromData(data(dropHpa: -7.5))!.pressureDropHpa,
      -7.5,
    );
    expect(
      PressureAlertMapper.fromData(data(dropHpa: '-7.5'))!.pressureDropHpa,
      -7.5,
    );
    expect(
      PressureAlertMapper.fromData(data(dropHpa: 'nonsense'))!.pressureDropHpa,
      isNull,
    );
  });

  group('fromRecord', () {
    test('the users/{uid} record becomes the same row as the push', () {
      final AppNotification? fromRecord = PressureAlertMapper.fromRecord(
        eventId: 'evt-1',
        occurredAt: DateTime.utc(2026, 8, 7, 6),
        dropHpa: -7.5,
      );
      final AppNotification? fromPush = PressureAlertMapper.fromData(data());

      expect(fromRecord, isNotNull);
      // Same id is the whole point: the reconcile must land on the row the push handler would have written, not beside it.
      expect(fromRecord!.id, fromPush!.id);
      expect(fromRecord.occurredAt, fromPush.occurredAt);
      expect(fromRecord.pressureDropHpa, fromPush.pressureDropHpa);
      expect(fromRecord.type, NotificationType.pressureAlert);
    });

    // An account that has never been sent an alert has none of these fields, which is the ordinary case on every launch — not an error.
    test('an empty or half-written record is no row', () {
      expect(
        PressureAlertMapper.fromRecord(eventId: null, occurredAt: null),
        isNull,
      );
      expect(
        PressureAlertMapper.fromRecord(eventId: 'evt-1', occurredAt: null),
        isNull,
      );
      expect(
        PressureAlertMapper.fromRecord(
          eventId: '',
          occurredAt: DateTime.utc(2026, 8, 7, 6),
        ),
        isNull,
      );
      expect(
        PressureAlertMapper.fromRecord(
          eventId: 42,
          occurredAt: DateTime.utc(2026, 8, 7, 6),
        ),
        isNull,
      );
    });

    test('a local timestamp is stored in UTC like every other row', () {
      final AppNotification? result = PressureAlertMapper.fromRecord(
        eventId: 'evt-1',
        occurredAt: DateTime(2026, 8, 7, 13),
      );

      expect(result!.occurredAt.isUtc, isTrue);
    });

    // The record predates lastAlertDropHpa, so old accounts carry an alert with no reading. The row is still worth having.
    test('a record with no drop still yields a row', () {
      final AppNotification? result = PressureAlertMapper.fromRecord(
        eventId: 'evt-1',
        occurredAt: DateTime.utc(2026, 8, 7, 6),
      );

      expect(result, isNotNull);
      expect(result!.pressureDropHpa, isNull);
    });
  });
}
