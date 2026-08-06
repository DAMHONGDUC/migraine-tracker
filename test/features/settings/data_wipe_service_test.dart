import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/medications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/settings/data/repositories/drift_export_record_repository.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_record.dart';
import 'package:migraine_tracker/features/settings/domain/enums/export_kind.dart';
import 'package:migraine_tracker/features/settings/domain/services/data_wipe_service.dart';

import '../../helpers/export_fakes.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sync_fakes.dart';

class RecordingNotificationScheduler implements NotificationScheduler {
  int cancelAllCalls = 0;

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

    await attacks.insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        location: HeadLocation.left,
      ),
    );
    await medications.upsert(const Medication(id: 'm1', name: 'Ibuprofen'));

    await DataWipeService(
      attacks,
      medications,
      notifications,
      exportRecords,
      exportFiles,
      FakeAuthRepository(),
      syncServiceOver(db),
    ).wipeAll();

    expect(notifications.cancelAllCalls, 1);
    expect(await attacks.getAll(), isEmpty);
    expect(await medications.getAll(), isEmpty);
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
      exportRecords,
      exportFiles,
      FakeAuthRepository(),
      syncServiceOver(db),
    ).wipeAll();

    expect(await exportRecords.getAll(), isEmpty);
    expect(exportFiles.files, isEmpty);
  });

  group('the account copy', () {
    Attack anAttack() => Attack(
      id: 'a1',
      startedAt: DateTime.now().toUtc(),
      intensity: 5,
      location: HeadLocation.left,
    );

    DataWipeService wipeFor(
      AppDatabase db, {
      required FakeAuthRepository auth,
      required FakeRemoteAttackRepository remote,
    }) => DataWipeService(
      DriftAttackRepository(db),
      DriftMedicationRepository(db),
      RecordingNotificationScheduler(),
      DriftExportRecordRepository(db),
      FakeExportFileStore(),
      auth,
      syncServiceOver(db, remote: remote),
    );

    test('is deleted too, or the wipe leaves the data online', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attacks = DriftAttackRepository(db);
      final remote = FakeRemoteAttackRepository();
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
      final remote = FakeRemoteAttackRepository()..failNextDeleteAll = true;

      await attacks.insert(anAttack());

      await expectLater(
        wipeFor(
          db,
          auth: FakeAuthRepository(signedIn: true),
          remote: remote,
        ).wipeAll(),
        throwsA(isA<Exception>()),
      );

      // Wiping the device first would leave the cloud copy with nothing left
      // to say it should go, and the next sync would pull it all back down.
      expect(await attacks.getAll(), hasLength(1));
    });

    test('is not chased for an account that never existed', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attacks = DriftAttackRepository(db);
      final remote = FakeRemoteAttackRepository();

      await attacks.insert(anAttack());

      // Anonymous: nothing was ever uploaded, so nothing is owed a delete.
      await wipeFor(
        db,
        auth: FakeAuthRepository(),
        remote: remote,
      ).wipeAll();

      expect(await attacks.getAll(), isEmpty);
    });
  });
}
