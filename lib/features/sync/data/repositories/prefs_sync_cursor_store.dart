import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/sync_collection.dart';
import '../../domain/repositories/sync_cursor_store.dart';

/// Cursor in `SecureStore`. Losing it costs one full re-pull, which is wasteful but never wrong, so it does not belong in the database.
class PrefsSyncCursorStore implements SyncCursorStore {
  const PrefsSyncCursorStore(this._store);

  final SecureStore _store;

  @override
  Future<DateTime?> lastPulledAt(String uid, SyncCollection collection) async {
    final int? millis = _store.getInt(_key(uid, collection));

    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  @override
  Future<void> save(String uid, SyncCollection collection, DateTime at) =>
      _store.setInt(_key(uid, collection), at.toUtc().millisecondsSinceEpoch);

  @override
  Future<DateTime?> lastSyncedAt(String uid) async {
    final int? millis = _store.getInt(
      '${PrefsKeyConstant.syncLastSyncedAtPrefix}$uid',
    );

    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  @override
  Future<void> saveSyncedAt(String uid, DateTime at) => _store.setInt(
    '${PrefsKeyConstant.syncLastSyncedAtPrefix}$uid',
    at.toUtc().millisecondsSinceEpoch,
  );

  @override
  Future<void> clear() async {
    final Iterable<String> keys = _store
        .getKeys()
        .where(
          (key) =>
              key.startsWith(PrefsKeyConstant.syncCursorPrefix) ||
              key.startsWith(PrefsKeyConstant.syncLastSyncedAtPrefix),
        )
        .toList();

    for (final String key in keys) {
      await _store.remove(key);
    }
  }

  String _key(String uid, SyncCollection collection) =>
      '${PrefsKeyConstant.syncCursorPrefix}${collection.name}_$uid';
}
