import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/daily_log/data/repositories/drift_daily_log_repository.dart';
import 'package:migraine_tracker/features/insights/data/repositories/drift_midas_repository.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/notifications/data/repositories/drift_notification_repository.dart';
import 'package:migraine_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:migraine_tracker/features/notifications/domain/enums/notification_type.dart';
import 'package:migraine_tracker/features/notifications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/settings/data/repositories/drift_export_record_repository.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_record.dart';
import 'package:migraine_tracker/features/settings/domain/enums/export_kind.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_wipe_service.dart';
import 'package:migraine_tracker/features/weather/data/repositories/drift_daily_pressure_repository.dart';

import '../../helpers/alert_fakes.dart';
import '../../helpers/attack_fakes.dart';
import '../../helpers/export_fakes.dart';
import '../../helpers/home_widget_fakes.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

class RecordingNotificationScheduler implements NotificationScheduler {
  @override
  Future<void> scheduleCheckIn({
    required DateTime when,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelCheckIn() async {}

  int cancelAllCalls = 0;

  @override
  Stream<String> get reminderTaps => const Stream<String>.empty();

  @override
  Future<String?> takeLaunchReminderId() async => null;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {}

  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {}
}

void main() {
  test('wipeAll cancels every scheduled reminder notification, not just the '
      'DB rows a cascade delete would remove', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final attacks = DriftAttackRepository(db);
    final medications = DriftMedicationRepository(db);
    final notifications = RecordingNotificationScheduler();
    final exportRecords = DriftExportRecordRepository(db);
    final exportFiles = FakeExportFileStore();
    final homeWidget = RecordingHomeWidgetRepository();
    final shareFiles = RecordingShareFileStore();

    await attacks.insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
    await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));
    await DriftNotificationRepository(db).addMissing(<AppNotification>[
      AppNotification(
        id: 'rem:r1:29000000',
        type: NotificationType.medicationReminder,
        occurredAt: DateTime.now().toUtc(),
        medicationId: 'm1',
        reminderId: 'r1',
      ),
    ]);

    await DataWipeService(
      attacks,
      medications,
      notifications,
      DriftNotificationRepository(db),
      exportRecords,
      exportFiles,
      FakeAuthRepository(),
      syncServiceOver(db),
      RecordingAlertRegistration(),
      DriftDailyPressureRepository(db),
      DriftDailyLogRepository(db),
      DriftMidasRepository(db),
      shareFiles,
      homeWidget,
      RecordingLiveActivity(),
    ).wipeAll();

    expect(notifications.cancelAllCalls, 1);
    // A shared attack is a fourth copy of health data on disk, sitting in temporary storage. "Delete all data" has to reach it too.
    expect(shareFiles.cleared, isTrue);
    expect(await attacks.getAll(), isEmpty);
    expect(await medications.getAll(), isEmpty);
    // The list is derived from reminders but stored, so a wipe that skipped it would keep naming medications the user just deleted.
    expect(await db.select(db.appNotifications).get(), isEmpty);
    // The App Group is off the database entirely, so nothing else here would notice the week count still sitting on the home screen.
    expect(homeWidget.clears, 1);
  });

  test('wipeAll deletes past exports — they are full copies of the data '
      'being erased', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final exportRecords = DriftExportRecordRepository(db);
    final exportFiles = FakeExportFileStore();
    final stored = await exportFiles.write(
      filename: 'baroease_export_2026-07-28_120000.json',
      bytes: Uint8List.fromList(utf8.encode('{"attacks":[]}')),
    );

    await exportRecords.insert(
      ExportRecord(
        id: 'e1',
        kind: ExportKind.json,
        filename: 'baroease_export_2026-07-28_120000.json',
        filePath: stored.path,
        sizeBytes: stored.sizeBytes,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    await DataWipeService(
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      RecordingNotificationScheduler(),
      DriftNotificationRepository(db),
      exportRecords,
      exportFiles,
      FakeAuthRepository(),
      syncServiceOver(db),
      RecordingAlertRegistration(),
      DriftDailyPressureRepository(db),
      DriftDailyLogRepository(db),
      DriftMidasRepository(db),
      RecordingShareFileStore(),
      RecordingHomeWidgetRepository(),
      RecordingLiveActivity(),
    ).wipeAll();

    expect(await exportRecords.getAll(), isEmpty);
    expect(exportFiles.files, isEmpty);
  });

  test('reports every step in order, ending on the last one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final reported = <int>[];

    await DataWipeService(
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      RecordingNotificationScheduler(),
      DriftNotificationRepository(db),
      DriftExportRecordRepository(db),
      FakeExportFileStore(),
      FakeAuthRepository(),
      syncServiceOver(db),
      RecordingAlertRegistration(),
      DriftDailyPressureRepository(db),
      DriftDailyLogRepository(db),
      DriftMidasRepository(db),
      RecordingShareFileStore(),
      RecordingHomeWidgetRepository(),
      RecordingLiveActivity(),
    ).wipeAll(
      onProgress: (done, steps) {
        expect(steps, DataWipeService.steps);
        reported.add(done);
      },
    );

    // Starts at 0 so the row can show a bar before the first step lands, then climbs one at a time and stops on the last.
    expect(reported, <int>[for (int i = 0; i <= DataWipeService.steps; i++) i]);
  });

  group('the account copy', () {
    Attack anAttack() => Attack(
      id: 'a1',
      startedAt: DateTime.now().toUtc(),
      intensity: 5,
      regions: const <HeadRegion>[HeadRegion.templeL],
    );

    DataWipeService wipeFor(
      AppDatabase db, {
      required FakeAuthRepository auth,
      required FakeRemoteSyncRepository remote,
    }) => DataWipeService(
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      RecordingNotificationScheduler(),
      DriftNotificationRepository(db),
      DriftExportRecordRepository(db),
      FakeExportFileStore(),
      auth,
      syncServiceOver(db, remote: remote),
      RecordingAlertRegistration(),
      DriftDailyPressureRepository(db),
      DriftDailyLogRepository(db),
      DriftMidasRepository(db),
      RecordingShareFileStore(),
      RecordingHomeWidgetRepository(),
      RecordingLiveActivity(),
    );

    test('is deleted too, or the wipe leaves the data online', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attacks = DriftAttackRepository(db);
      final remote = FakeRemoteSyncRepository();
      final auth = FakeAuthRepository(signedIn: true);

      await attacks.insert(anAttack());
      await syncServiceOver(db, remote: remote).sync('test-uid');
      expect(remote.documents, isNotEmpty);

      await wipeFor(db, auth: auth, remote: remote).wipeAll();

      expect(remote.documents, isEmpty);
      expect(await attacks.getAll(), isEmpty);
    });

    test('failing to clear it aborts the whole wipe', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attacks = DriftAttackRepository(db);
      final remote = FakeRemoteSyncRepository()..failNextDeleteAll = true;

      await attacks.insert(anAttack());

      await expectLater(
        wipeFor(
          db,
          auth: FakeAuthRepository(signedIn: true),
          remote: remote,
        ).wipeAll(),
        throwsA(isA<Exception>()),
      );

      // Wiping the device first would leave the cloud copy with nothing left to say it should go, and the next sync would pull it all back down.
      expect(await attacks.getAll(), hasLength(1));
    });

    test('gives up the push token, or alerts keep arriving', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final alerts = RecordingAlertRegistration();

      await DataWipeService(
        DriftAttackRepository(db),
        DriftMedicationRepository(db),
        RecordingNotificationScheduler(),
        DriftNotificationRepository(db),
        DriftExportRecordRepository(db),
        FakeExportFileStore(),
        FakeAuthRepository(signedIn: true),
        syncServiceOver(db),
        alerts,
        DriftDailyPressureRepository(db),
        DriftDailyLogRepository(db),
        DriftMidasRepository(db),
        RecordingShareFileStore(),
        RecordingHomeWidgetRepository(),
        RecordingLiveActivity(),
      ).wipeAll();

      // The FCM token is the one thing that can still reach someone after they deleted everything.
      expect(alerts.forgetCalls, 1);
    });

    test('is not chased for an account that never existed', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attacks = DriftAttackRepository(db);
      final remote = FakeRemoteSyncRepository();

      await attacks.insert(anAttack());

      // Anonymous: nothing was ever uploaded, so nothing is owed a delete.
      await wipeFor(db, auth: FakeAuthRepository(), remote: remote).wipeAll();

      expect(await attacks.getAll(), isEmpty);
    });
  });
}
