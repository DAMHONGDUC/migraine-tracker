import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/prefs_key_constant.dart';

import '../../domain/entities/sync_collection.dart';
import '../../domain/repositories/sync_cursor_store.dart';

/// Cursor in shared_preferences. Losing it costs one full re-pull, which is
/// wasteful but never wrong, so it does not belong in the database.
class PrefsSyncCursorStore implements SyncCursorStore {
  const PrefsSyncCursorStore(this._prefs);


  final SharedPreferences _prefs;

  @override
  Future<DateTime?> lastPulledAt(String uid, SyncCollection collection) async {
    final int? millis = _prefs.getInt(_key(uid, collection));

    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  @override
  Future<void> save(String uid, SyncCollection collection, DateTime at) =>
      _prefs.setInt(_key(uid, collection), at.toUtc().millisecondsSinceEpoch);

  @override
  Future<DateTime?> lastSyncedAt(String uid) async {
    final int? millis = _prefs.getInt('$PrefsKeyConstant.syncLastSyncedAtPrefix$uid');

    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  @override
  Future<void> saveSyncedAt(String uid, DateTime at) => _prefs.setInt(
    '$PrefsKeyConstant.syncLastSyncedAtPrefix$uid',
    at.toUtc().millisecondsSinceEpoch,
  );

  @override
  Future<void> clear() async {
    final Iterable<String> keys = _prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(PrefsKeyConstant.syncCursorPrefix) || key.startsWith(PrefsKeyConstant.syncLastSyncedAtPrefix),
        )
        .toList();

    for (final String key in keys) {
      await _prefs.remove(key);
    }
  }

  String _key(String uid, SyncCollection collection) =>
      '$PrefsKeyConstant.syncCursorPrefix${collection.name}_$uid';
}
