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

  /// The whole pass — pull, then push — for the signed-in account, if there is one. Launch, resume and sign-in; the cooldown holds back the pull half only.
  Future<void> sync() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn || _passQueued) return;
    _passQueued = true;
    return _enqueue(() async {
      _passQueued = false;
      // Read here rather than before the queue: the pass in front may have just stamped it.
      if (await _isCoolingDown(user.uid)) {
        // The floor is about the pull, and what this device owes must not wait behind it: a write-through push that failed offline has nothing else to retry it — the next pass can be six hours off, and a user who logs nothing more never fires another. Costs four local queries and no network when there is nothing pending.
        await _push(user.uid);

        return;
      }
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

  /// Everything the device still owes, with the answer sign-out needs: did it all reach the server?
  ///
  /// [pushPending] is fire-and-forget and says nothing, which is right for a
  /// write — the next write or the next pass retries it. Sign-out has no next
  /// time: it wipes the device's copy, so a record that did not make it up is a
  /// record that is gone. False is therefore "do not wipe", and the caller
  /// stops there.
  ///
  /// Not collapsed like [pushPending]: two callers each need their own answer,
  /// and a queued one cannot give a second caller a result it never waited for.
  Future<bool> flushPending() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn) return false;

    bool flushed = false;

    await _enqueue(() async {
      try {
        final int pushed = await ref
            .read(syncServiceProvider)
            .pushPending(user.uid, onProgress: _showProgress);

        SdLogger.info(LogTagConstant.sync, 'Pending changes flushed', {
          'pushed': pushed,
        });
        flushed = true;
      } catch (error, stackTrace) {
        SdLogger.error(
          LogTagConstant.sync,
          'Flushing pending changes failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      await _settle(failed: !flushed);
    });
    return flushed;
  }

  /// Dev menu only: forgets every pull cursor and runs a whole pass now, cooldown or not.
  ///
  /// Without the cursors the pull reads the account's whole history again, so
  /// there is real data to move and the Settings card's bar has something to
  /// show. Safe: pulled rows go through the same last-write-wins as any pull,
  /// and the pass restamps the cooldown when it lands.
  Future<bool> syncEverythingNow() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn) return false;
    SdLogger.action(LogTagConstant.sync, 'Dev: sync everything now');

    bool synced = false;

    await _enqueue(() async {
      try {
        await ref.read(syncCursorStoreProvider).clear();
      } catch (error, stackTrace) {
        SdLogger.error(
          LogTagConstant.sync,
          'Clearing the cursors for a full sync failed',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      synced = await _run(user.uid);
    });
    return synced;
  }

  /// Neither task throws — both catch their own — so the chain cannot be poisoned by one failure.
  Future<void> _enqueue(Future<void> Function() task) =>
      _queue = _queue.then((_) => task());

  /// Clears the account's sync state on sign-out: the cached key and every cursor.
  ///
  /// It does not touch the records — `AccountController.signOut` has already
  /// wiped them, after pushing what was still owed. Dropping the cursors is
  /// what makes that wipe recoverable: they point past everything just
  /// removed, so signing back in with them in place would pull only what
  /// changed since and the history would never come home.
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

  /// True when the pass landed.
  Future<bool> _run(String uid) async {
    final bool isFirstPull = await _isFirstPull(uid);

    state = SyncStatus(
      phase: SyncPhase.syncing,
      isFirstPull: isFirstPull,
      pending: state.pending,
    );
    try {
      final SyncOutcome outcome = await ref
          .read(syncServiceProvider)
          .sync(uid, onProgress: _showProgress);

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
      await _settle();

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Attack sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      // Deliberately not rethrown: the next launch, resume or logged attack retries, and nothing on screen was waiting on this.
      await _settle(failed: true);

      return false;
    }
  }

  /// State for the Settings card, but no cooldown stamp: a push is not the pull the cooldown is about. A failure waits for the next write or the next pass.
  Future<void> _push(String uid) async {
    bool failed = false;

    try {
      final int pushed = await ref
          .read(syncServiceProvider)
          .pushPending(uid, onProgress: _showProgress);

      // Every real push schedules one more that finds nothing — marking a record synced is itself a write. Logging those would bury the ones that moved something.
      if (pushed > 0) {
        SdLogger.info(LogTagConstant.sync, 'Local changes pushed', {
          'pushed': pushed,
        });
      }
    } catch (error, stackTrace) {
      failed = true;
      SdLogger.error(
        LogTagConstant.sync,
        'Pushing local changes failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _settle(failed: failed);
  }

  /// The service's count, straight onto the card. The first call of a push is also what shows it running — a push that finds nothing never calls, so it never flickers the card.
  void _showProgress(int done, int total) {
    state = state.copyWith(phase: SyncPhase.syncing, done: done, total: total);
  }

  /// Ends a pass or push: back to idle (or failed), progress cleared, and the owed count re-read — it is what the card and a coming sign-out both need.
  Future<void> _settle({bool failed = false}) async {
    final int? pending = await _pendingCount();

    state = SyncStatus(
      phase: failed ? SyncPhase.failed : SyncPhase.idle,
      pending: pending ?? state.pending,
    );
  }

  /// Null when the count could not be read: the card keeps the last one rather than claiming nothing is owed.
  Future<int?> _pendingCount() async {
    try {
      return await ref.read(syncServiceProvider).pendingCount();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Counting pending changes failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
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
