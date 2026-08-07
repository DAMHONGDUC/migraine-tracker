import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../../sync/domain/entities/sync_record.dart';
import '../../domain/entities/app_notification.dart';

/// The notifications side of sync.
///
/// Nothing here holds a foreign key, so unlike reminders a row never has to
/// wait for something else to arrive first — it is last in the collection
/// order only so the medication and reminder it names are already on the
/// device when the list renders it.
class DriftAppNotificationSyncStore
    extends DriftSyncLocalStore<AppNotification> {
  const DriftAppNotificationSyncStore(super.db);

  @override
  SyncCollection get collection => SyncCollection.notifications;

  @override
  String idOf(AppNotification value) => value.id;

  @override
  Future<List<SyncRecord<AppNotification>>> loadDirty() async {
    final List<AppNotificationRow> rows =
        await (db.select(db.appNotifications)..where(
              (r) =>
                  r.syncedRevision.isNull() |
                  r.syncedRevision.isNotExp(r.revision),
            ))
            .get();

    return rows
        .map(
          (row) => SyncRecord<AppNotification>(
            id: row.id,
            updatedAt: (row.updatedAt ?? _beginning).toUtc(),
            revision: row.revision,
            value: _toDomain(row),
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
    AppNotification value,
    DateTime updatedAt,
    int revision,
  ) async {
    await db
        .into(db.appNotifications)
        .insertOnConflictUpdate(
          AppNotificationsCompanion.insert(
            id: value.id,
            type: value.type,
            occurredAt: value.occurredAt,
            readAt: Value(value.readAt),
            medicationId: Value(value.medicationId),
            reminderId: Value(value.reminderId),
            pressureDropHpa: Value(value.pressureDropHpa),
            updatedAt: Value(updatedAt),
            revision: Value(revision),
            syncedRevision: Value(revision),
          ),
        );
    return true;
  }

  @override
  Future<void> deleteRow(String id) =>
      (db.delete(db.appNotifications)..where((r) => r.id.equals(id))).go();

  @override
  Future<void> writeSyncedRevision(String id, int revision) async {
    await (db.update(db.appNotifications)
          ..where((r) => r.id.equals(id) & r.revision.equals(revision)))
        .write(AppNotificationsCompanion(syncedRevision: Value(revision)));
  }

  AppNotification _toDomain(AppNotificationRow row) => AppNotification(
    id: row.id,
    type: row.type,
    occurredAt: row.occurredAt,
    readAt: row.readAt,
    medicationId: row.medicationId,
    reminderId: row.reminderId,
    pressureDropHpa: row.pressureDropHpa,
  );

  Future<AppNotificationRow?> _row(String id) => (db.select(
    db.appNotifications,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Matches the other stores: a row with no `updatedAt` has nothing to date
  /// it by, so any remote copy wins.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
}
