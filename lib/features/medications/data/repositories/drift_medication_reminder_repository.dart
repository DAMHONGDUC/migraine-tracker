import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../domain/entities/medication_reminder.dart';
import '../../domain/repositories/medication_reminder_repository.dart';

class DriftMedicationReminderRepository
    implements MedicationReminderRepository {
  const DriftMedicationReminderRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<MedicationReminderView>> watchAll() {
    final query = _db.select(_db.medicationReminders).join([
      innerJoin(
        _db.medications,
        _db.medications.id.equalsExp(_db.medicationReminders.medicationId),
      ),
    ])..orderBy([OrderingTerm.asc(_db.medicationReminders.minuteOfDay)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final r = row.readTable(_db.medicationReminders);
        return MedicationReminderView(
          reminder: _toDomain(r),
          medicationName: row.readTable(_db.medications).name,
        );
      }).toList(),
    );
  }

  @override
  Future<List<MedicationReminder>> getAllEnabled() async {
    final rows = await (_db.select(
      _db.medicationReminders,
    )..where((t) => t.enabled.equals(true))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> upsert(MedicationReminder reminder) {
    return _db.transaction(() async {
      final MedicationReminderRow? existing = await (_db.select(
        _db.medicationReminders,
      )..where((t) => t.id.equals(reminder.id))).getSingleOrNull();

      await _db
          .into(_db.medicationReminders)
          .insertOnConflictUpdate(
            MedicationRemindersCompanion.insert(
              id: reminder.id,
              medicationId: reminder.medicationId,
              minuteOfDay: reminder.minuteOfDay,
              enabled: Value(reminder.enabled),
              updatedAt: Value(DateTime.now().toUtc()),
              revision: Value((existing?.revision ?? 0) + 1),
              syncedRevision: Value(existing?.syncedRevision),
            ),
          );
      await SyncTombstoneWriter.clear(_db, SyncCollection.medicationReminders, [
        reminder.id,
      ]);
    });
  }

  /// Really deletes, and leaves a tombstone holding only the id so the
  /// deletion still reaches the user's other devices.
  @override
  Future<void> deleteById(String id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.medicationReminders,
      )..where((t) => t.id.equals(id))).go();
      await SyncTombstoneWriter.write(_db, SyncCollection.medicationReminders, [
        id,
      ]);
    });
  }

  /// GDPR wipe. Tombstones go too: the remote copy is deleted wholesale in
  /// the same pass, so there is nothing left to tell the server about.
  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.medicationReminders).go();
      await SyncTombstoneWriter.clearAll(
        _db,
        SyncCollection.medicationReminders,
      );
    });
  }

  MedicationReminder _toDomain(MedicationReminderRow row) => MedicationReminder(
    id: row.id,
    medicationId: row.medicationId,
    minuteOfDay: row.minuteOfDay,
    enabled: row.enabled,
  );
}
