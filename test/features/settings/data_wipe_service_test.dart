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
    ).wipeAll();

    expect(await exportRecords.getAll(), isEmpty);
    expect(exportFiles.files, isEmpty);
  });
}
