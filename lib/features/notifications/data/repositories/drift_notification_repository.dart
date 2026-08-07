import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class DriftNotificationRepository implements NotificationRepository {
  const DriftNotificationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<AppNotification>> watchAll() {
    final query = _db.select(_db.appNotifications)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);

    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<int> watchUnreadCount() {
    final Expression<int> count = _db.appNotifications.id.count();
    final query = _db.selectOnly(_db.appNotifications)
      ..addColumns([count])
      ..where(_db.appNotifications.readAt.isNull());

    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<void> addMissing(List<AppNotification> notifications) {
    if (notifications.isEmpty) return Future<void>.value();

    return _db.batch((Batch batch) {
      batch.insertAll(
        _db.appNotifications,
        <AppNotificationsCompanion>[
          for (final AppNotification notification in notifications)
            AppNotificationsCompanion.insert(
              id: notification.id,
              kind: notification.kind,
              occurredAt: notification.occurredAt,
              readAt: Value(notification.readAt),
              medicationId: Value(notification.medicationId),
              reminderId: Value(notification.reminderId),
              pressureDropHpa: Value(notification.pressureDropHpa),
              updatedAt: Value(DateTime.now().toUtc()),
              revision: const Value(1),
            ),
        ],
        // The whole point of a derived id: a row already here is the same
        // row, so ignoring the second write costs nothing and protects the
        // read state it already carries.
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  @override
  Future<void> markAllRead(DateTime at) {
    return _db.transaction(() async {
      final List<AppNotificationRow> unread = await (_db.select(
        _db.appNotifications,
      )..where((t) => t.readAt.isNull())).get();

      // Row by row rather than one `write`: the revision has to go up by one
      // per row, and that is what carries the read state to the other
      // devices — a row whose revision did not move never syncs. The loop is
      // over unread rows only, so it is short by construction.
      for (final AppNotificationRow row in unread) {
        await (_db.update(
          _db.appNotifications,
        )..where((t) => t.id.equals(row.id))).write(
          AppNotificationsCompanion(
            readAt: Value(at.toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
            revision: Value(row.revision + 1),
          ),
        );
      }
    });
  }

  /// GDPR wipe. Tombstones go too — the remote copy is deleted wholesale in
  /// the same pass, so there is nothing left to tell the server about.
  @override
  Future<void> deleteAll() {
    return _db.transaction(() async {
      await _db.delete(_db.appNotifications).go();
      await SyncTombstoneWriter.clearAll(_db, SyncCollection.notifications);
    });
  }

  AppNotification _toDomain(AppNotificationRow row) => AppNotification(
    id: row.id,
    kind: row.kind,
    occurredAt: row.occurredAt,
    readAt: row.readAt,
    medicationId: row.medicationId,
    reminderId: row.reminderId,
    pressureDropHpa: row.pressureDropHpa,
  );
}
