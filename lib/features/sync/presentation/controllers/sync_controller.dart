import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/sync_constant.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/entities/sync_status.dart';
import '../../providers.dart';

/// Runs sync and holds the only state the UI may see.
class SyncController extends Notifier<SyncStatus> {
  /// One at a time, in the order asked. A push that overlapped a pass would send the same record twice — and mark it synced while the other one was still writing it.
  Future<void> _queue = Future<void>.value();

  /// Whether one of each is already waiting. Two writes a second apart owe the server one push, not two, and ten app opens owe it one pass.
  bool _passQueued = false;
  bool _pushQueued = false;

  @override
  SyncStatus build() => const SyncStatus();

  /// The whole pass — pull, then push — for the signed-in account, if there is one. Launch, resume and sign-in; held back by the cooldown.
  Future<void> sync() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn || _passQueued) return;
    _passQueued = true;
    return _enqueue(() async {
      _passQueued = false;
      // Read here rather than before the queue: the pass in front may have just stamped it.
      if (await _isCoolingDown(user.uid)) return;
      await _run(user.uid);
    });
  }

  /// Sends what the device owes the server and pulls nothing — fired by every local write to a synced table (hard rule 12).
  Future<void> pushPending() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn || _pushQueued) return;
    _pushQueued = true;
    return _enqueue(() async {
      _pushQueued = false;
      await _push(user.uid);
    });
  }

  /// Neither task throws — both catch their own — so the chain cannot be poisoned by one failure.
  Future<void> _enqueue(Future<void> Function() task) =>
      _queue = _queue.then((_) => task());

  /// Clears the account's sync state on sign-out. Local attacks stay — they are the source of truth, and signing out is not a delete.
  Future<void> onSignedOut() async {
    state = const SyncStatus();
    try {
      await ref.read(syncServiceProvider).onSignedOut();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Clearing sync state failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _run(String uid) async {
    final bool isFirstPull = await _isFirstPull(uid);

    state = SyncStatus(phase: SyncPhase.syncing, isFirstPull: isFirstPull);
    try {
      final SyncOutcome outcome = await ref.read(syncServiceProvider).sync(uid);

      SdLogger.info(LogTagConstant.sync, 'Attacks synced', {
        'pushed': outcome.pushed,
        'pulled': outcome.pulled,
      });
      AppAnalytics.logAttacksSynced(
        pushed: outcome.pushed,
        pulled: outcome.pulled,
      );
      // Data is up there that this build cannot read: never expected, and invisible to the user, so it has to reach us some other way.
      if (outcome.unreadable > 0) {
        SdLogger.error(
          LogTagConstant.sync,
          'Undecryptable synced attacks skipped',
          error: StateError('${outcome.unreadable} attack payloads unreadable'),
          stackTrace: StackTrace.current,
          data: {'unreadable': outcome.unreadable},
        );
      }
      await _stampSyncedAt(uid);
      state = const SyncStatus();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Attack sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      // Deliberately not rethrown: the next launch, resume or logged attack retries, and nothing on screen was waiting on this.
      state = state.copyWith(phase: SyncPhase.failed, isFirstPull: false);
    }
  }

  /// No state and no cooldown stamp: nothing on screen shows a push, and a push is not the pull the cooldown is about. A failure waits for the next write or the next pass.
  Future<void> _push(String uid) async {
    try {
      final int pushed = await ref.read(syncServiceProvider).pushPending(uid);

      // Every real push schedules one more that finds nothing — marking a record synced is itself a write. Logging those would bury the ones that moved something.
      if (pushed == 0) return;
      SdLogger.info(LogTagConstant.sync, 'Local changes pushed', {
        'pushed': pushed,
      });
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Pushing local changes failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Whether a pass finished recently enough to skip this one.
  Future<bool> _isCoolingDown(String uid) async {
    try {
      final DateTime? last = await ref
          .read(syncCursorStoreProvider)
          .lastSyncedAt(uid);

      if (last == null) return false;
      return DateTime.now().toUtc().difference(last) <
          SyncConstant.automaticCooldown;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Reading the sync cooldown failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Only after a pass that worked: a failure must be retried by the next open, not held off for another six hours.
  Future<void> _stampSyncedAt(String uid) async {
    try {
      await ref
          .read(syncCursorStoreProvider)
          .saveSyncedAt(uid, DateTime.now().toUtc());
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Recording the sync time failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Null rather than throwing: a push follows every write, and saving an attack must not fail because auth is unavailable (hard rule 4).
  AuthUser? _currentUser() {
    try {
      return ref.read(authRepositoryProvider).currentUser;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Reading the signed-in user failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> _isFirstPull(String uid) async {
    try {
      return await ref.read(syncServiceProvider).isFirstPull(uid);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Reading the sync cursor failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
