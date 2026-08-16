import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../sync/data/repositories/drift_sync_local_store.dart';
import '../../../sync/domain/entities/sync_collection.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_type.dart';
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
              type: notification.type,
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
  Future<AppNotification?> latestForReminder(String reminderId) async {
    final query = _db.select(_db.appNotifications)
      ..where((t) => t.reminderId.equals(reminderId))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(1);
    final AppNotificationRow? row = await query.getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<AppNotification?> latestPressureAlert() async {
    final query = _db.select(_db.appNotifications)
      ..where((t) => t.type.equalsValue(NotificationType.pressureAlert))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(1);
    final AppNotificationRow? row = await query.getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> markRead(String id, DateTime at) {
    return _db.transaction(() async {
      final AppNotificationRow? row = await (_db.select(
        _db.appNotifications,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      // Already read, or gone: bumping the revision would push a row that
      // says exactly what the server already has.
      if (row == null || row.readAt != null) return;
      await (_db.update(
        _db.appNotifications,
      )..where((t) => t.id.equals(id))).write(
        AppNotificationsCompanion(
          readAt: Value(at.toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          // Bumped, or the read state looks unchanged and never syncs.
          revision: Value(row.revision + 1),
        ),
      );
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
    type: row.type,
    occurredAt: row.occurredAt,
    readAt: row.readAt,
    medicationId: row.medicationId,
    reminderId: row.reminderId,
    pressureDropHpa: row.pressureDropHpa,
  );
}
