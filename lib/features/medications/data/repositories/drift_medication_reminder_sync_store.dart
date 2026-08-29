import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/medication_reminder.dart';

/// The reminders side of sync.
class DriftMedicationReminderSyncStore
    extends DriftSyncLocalStore<MedicationReminder> {
  const DriftMedicationReminderSyncStore(super.db);

  @override
  SyncCollection get collection => SyncCollection.medicationReminders;

  @override
  String idOf(MedicationReminder value) => value.id;

  @override
  Future<List<SyncRecord<MedicationReminder>>> loadDirty() async {
    final List<MedicationReminderRow> rows =
        await (db.select(db.medicationReminders)..where(
              (r) =>
                  r.syncedRevision.isNull() |
                  r.syncedRevision.isNotExp(r.revision),
            ))
            .get();

    return rows
        .map(
          (row) => SyncRecord<MedicationReminder>(
            id: row.id,
            updatedAt: (row.updatedAt ?? _beginning).toUtc(),
            revision: row.revision,
            value: MedicationReminder(
              id: row.id,
              medicationId: row.medicationId,
              minuteOfDay: row.minuteOfDay,
              enabled: row.enabled,
              createdAt: row.createdAt,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> localUpdatedAt(String id) async =>
      (await _row(id))?.updatedAt?.toUtc();

  @override
  Future<int> nextRevision(String id) async =>
      ((await _row(id))?.revision ?? 0) + 1;

  @override
  Future<bool> writeFromRemote(
    MedicationReminder value,
    DateTime updatedAt,
    int revision,
  ) async {
    // A reminder points at a medication.
    final bool hasMedication =
        await (db.select(
          db.medications,
        )..where((m) => m.id.equals(value.medicationId))).getSingleOrNull() !=
        null;

    if (!hasMedication) return false;

    await db
        .into(db.medicationReminders)
        .insertOnConflictUpdate(
          MedicationRemindersCompanion.insert(
            id: value.id,
            medicationId: value.medicationId,
            minuteOfDay: value.minuteOfDay,
            enabled: Value(value.enabled),
            createdAt: Value(value.createdAt),
            updatedAt: Value(updatedAt),
            revision: Value(revision),
            syncedRevision: Value(revision),
          ),
        );
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.medicationReminders)..where((r) => r.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    await (db.update(db.medicationReminders)
          ..where((r) => r.id.equals(id) & r.revision.equals(revision)))
        .write(MedicationRemindersCompanion(syncedRevision: Value(revision)));
  }

  Future<MedicationReminderRow?> _row(String id) => (db.select(
    db.medicationReminders,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Rows saved before v7 have no `updatedAt` and nothing else to date them by, so any remote copy wins.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
}
