import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/sync_constant.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/enums/sync_trigger.dart';
import '../../providers.dart';

/// Runs attack sync and holds the only state the UI may see.
class SyncController extends Notifier<SyncStatus> {
  Future<void>? _inFlight;

  /// The floor between two [SyncTrigger.automatic] passes.

  @override
  SyncStatus build() => const SyncStatus();

  /// Syncs the signed-in account, if there is one.
  Future<void> sync({SyncTrigger trigger = SyncTrigger.automatic}) async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn) return;
    if (trigger == SyncTrigger.automatic && await _isCoolingDown(user.uid)) {
      return;
    }
    return _inFlight ??= _run(user.uid).whenComplete(() => _inFlight = null);
  }

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
    int shownPercent = 0;

    state = SyncStatus(phase: SyncPhase.syncing, isFirstPull: isFirstPull);
    try {
      final SyncOutcome outcome = await ref
          .read(syncServiceProvider)
          .sync(
            uid,
            // Only when the whole percent moves: the service reports once per record, and a thousand-record account would otherwise rebuild the row a thousand.
            onProgress: (double fraction) {
              final int percent = (fraction * 100).round();

              if (percent == shownPercent) return;
              shownPercent = percent;
              state = state.copyWith(progress: fraction);
            },
          );

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
      state = SyncStatus(lastSyncedAt: DateTime.now());
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

  /// Null rather than throwing: the log flow fires sync straight after saving an attack, and must not fail because auth is unavailable (hard rule 4).
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
