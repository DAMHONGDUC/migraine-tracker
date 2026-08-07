import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_kind.dart';
import 'package:migraine_tracker/features/notifications/domain/services/pressure_alert_mapper.dart';

Map<String, dynamic> data({
  String kind = 'pressureAlert',
  Object? eventId = 'evt-1',
  Object? at = '2026-08-07T06:00:00.000Z',
  Object? dropHpa = '-7.5',
}) => <String, dynamic>{
  'kind': kind,
  'eventId': ?eventId,
  'at': ?at,
  'dropHpa': ?dropHpa,
};

void main() {
  test('a well-formed alert becomes a row keyed by its event', () {
    final AppNotification? result = PressureAlertMapper.fromData(data());

    expect(result, isNotNull);
    expect(result!.kind, NotificationKind.pressureAlert);
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
    expect(PressureAlertMapper.fromData(data(kind: 'somethingElse')), isNull);
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

    // The sheet leaves the number out rather than printing one the forecast
    // never gave.
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
}
