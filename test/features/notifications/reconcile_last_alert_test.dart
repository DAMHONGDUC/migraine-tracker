import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/domain/repositories/last_alert_repository.dart';
import 'package:migraine_tracker/features/notifications/providers.dart';

import '../../helpers/notification_fakes.dart';

/// The reconcile writes through the real Drift repository, because what is
/// being proved is that re-running it does not duplicate or un-read a row —
/// and that is the store's behaviour, not the controller's.
void main() {
  late AppDatabase db;

  AppNotification alert({String eventId = 'evt-1', double? drop = -7.5}) =>
      AppNotification(
        id: AppNotification.pressureAlertId(eventId),
        type: NotificationType.pressureAlert,
        occurredAt: DateTime.utc(2026, 8, 7, 6),
        pressureDropHpa: drop,
      );

  ProviderContainer containerWith(LastAlertRepository lastAlert) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        lastAlertRepositoryProvider.overrideWithValue(lastAlert),
      ],
    );

    addTearDown(container.dispose);
    return container;
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('an alert on record becomes a row', () async {
    final ProviderContainer container = containerWith(
      FakeLastAlertRepository(alert: alert()),
    );

    await container.read(notificationsControllerProvider).reconcileLastAlert();

    final List<AppNotification> rows = await container
        .read(notificationRepositoryProvider)
        .watchAll()
        .first;

    expect(rows.length, 1);
    expect(rows.single.id, 'pa:evt-1');
    expect(rows.single.pressureDropHpa, -7.5);
  });

  test('nothing on record leaves the list alone', () async {
    final ProviderContainer container = containerWith(
      FakeLastAlertRepository(),
    );

    await container.read(notificationsControllerProvider).reconcileLastAlert();

    expect(
      await container
          .read(notificationRepositoryProvider)
          .watchAll()
          .first,
      isEmpty,
    );
  });

  // It runs on every launch and every resume against a doc that only ever
  // holds the latest alert, so it re-writes the same row constantly.
  test('running it again does not duplicate the row', () async {
    final ProviderContainer container = containerWith(
      FakeLastAlertRepository(alert: alert()),
    );

    await container.read(notificationsControllerProvider).reconcileLastAlert();
    await container.read(notificationsControllerProvider).reconcileLastAlert();
    await container.read(notificationsControllerProvider).reconcileLastAlert();

    expect(
      (await container
              .read(notificationRepositoryProvider)
              .watchAll()
              .first)
          .length,
      1,
    );
  });

  // The badge coming back on every launch is exactly what insert-if-absent
  // exists to prevent (hard rule 16).
  test('a row the user has read stays read', () async {
    final ProviderContainer container = containerWith(
      FakeLastAlertRepository(alert: alert()),
    );

    await container.read(notificationsControllerProvider).reconcileLastAlert();
    await container.read(notificationsControllerProvider).markRead('pa:evt-1');
    await container.read(notificationsControllerProvider).reconcileLastAlert();

    final List<AppNotification> rows = await container
        .read(notificationRepositoryProvider)
        .watchAll()
        .first;

    expect(rows.single.isRead, isTrue);
  });

  // It runs unawaited at launch: a throw here must not take the app start
  // with it, so this method is the one that swallows rather than rethrows.
  test('a failed read is swallowed, not rethrown', () async {
    final ProviderContainer container = containerWith(
      ThrowingLastAlertRepository(),
    );

    await expectLater(
      container.read(notificationsControllerProvider).reconcileLastAlert(),
      completes,
    );
    expect(
      await container
          .read(notificationRepositoryProvider)
          .watchAll()
          .first,
      isEmpty,
    );
  });
}
