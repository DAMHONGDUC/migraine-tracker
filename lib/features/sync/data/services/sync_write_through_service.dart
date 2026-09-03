import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/constants/sync_constant.dart';
import '../../../../core/db/app_database.dart';

/// Turns every local write to a synced table into a push, so a signed-in account's data is on the server as it is made rather than at the next launch (hard rule 12).
///
/// It watches the tables instead of asking each controller to remember a call
/// after its own save: a rule that has to be repeated at every new write is one
/// that is already broken somewhere, and a new synced table joins this by being
/// added to the list below rather than by touching its feature.
class SyncWriteThroughService {
  SyncWriteThroughService(this._db, this._push);

  final AppDatabase _db;

  /// What a change owes the server. Passed in rather than read here: this is the data layer, and the push lives in a controller.
  final Future<void> Function() _push;

  StreamSubscription<Set<TableUpdate>>? _updates;
  Timer? _debounce;

  /// Every table sync carries, plus the tombstones a delete leaves — a deletion writes nothing to the table it removes the row from.
  List<ResultSetImplementation<dynamic, dynamic>> get _syncedTables =>
      <ResultSetImplementation<dynamic, dynamic>>[
        _db.medications,
        _db.medicationReminders,
        _db.attacks,
        _db.dailyLogs,
        _db.appNotifications,
        _db.syncTombstones,
      ];

  /// Idempotent: the app root starts it on every build, and only the first one subscribes.
  void start() {
    _updates ??= _db
        .tableUpdates(TableUpdateQuery.onAllTables(_syncedTables))
        .listen(_schedule);
  }

  void dispose() {
    _debounce?.cancel();
    _debounce = null;
    unawaited(_updates?.cancel());
    _updates = null;
  }

  /// A pull writes rows too, and so does marking a record synced. Both schedule a push that finds nothing pending and costs no network — that is what keeps this from being a loop.
  void _schedule(Set<TableUpdate> _) {
    // Restarted rather than left to run: an edit that writes four rows owes one push, not four.
    _debounce?.cancel();
    _debounce = Timer(SyncConstant.writeThroughDebounce, () {
      _debounce = null;
      unawaited(_push());
    });
  }
}
