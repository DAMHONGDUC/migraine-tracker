import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/enums/sync_trigger.dart';
import '../../providers.dart';

/// Runs attack sync and holds the only state the UI may see.
///
/// Never throws to its callers: every trigger fires it unawaited and no
/// screen waits on it (hard rule 12), so a failure is logged and left for the
/// next pass rather than surfaced as an error the user must dismiss.
class SyncController extends Notifier<SyncStatus> {
  Future<void>? _inFlight;

  /// The floor between two [SyncTrigger.automatic] passes.
  ///
  /// Without it every launch and every resume ran a whole pass: ten app
  /// opens in ten minutes were ten passes, each a callable plus a query
  /// and a push per collection, usually to find nothing had changed.
  ///
  /// Six hours is the owner's number, and the cost is stated plainly: a
  /// change made on another device can wait that long to arrive unless
  /// the user logs an attack or syncs by hand — both of which skip this.
  static const Duration automaticCooldown = Duration(hours: 6);

  @override
  SyncStatus build() => const SyncStatus();

  /// Syncs the signed-in account, if there is one.
  ///
  /// Concurrent calls join the running pass instead of starting a second: the
  /// launch, resume and after-logging triggers all overlap in normal use, and
  /// two passes at once would push the same records twice.
  ///
  /// An [SyncTrigger.automatic] call inside [automaticCooldown] of the last
  /// finished pass does nothing at all — no state change, so a skipped pass
  /// is invisible rather than looking like a failure or a fresh sync.
  Future<void> sync({SyncTrigger trigger = SyncTrigger.automatic}) async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn) return;
    if (trigger == SyncTrigger.automatic && await _isCoolingDown(user.uid)) {
      return;
    }
    return _inFlight ??= _run(user.uid).whenComplete(() => _inFlight = null);
  }

  /// Clears the account's sync state on sign-out. Local attacks stay — they
  /// are the source of truth, and signing out is not a delete.
  Future<void> onSignedOut() async {
    state = const SyncStatus();
    try {
      await ref.read(syncServiceProvider).onSignedOut();
    } catch (error, stackTrace) {
      AppLogger.error(
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
            // Only when the whole percent moves: the service reports once per
            // record, and a thousand-record account would otherwise rebuild
            // the row a thousand times to draw the same number.
            onProgress: (double fraction) {
              final int percent = (fraction * 100).round();

              if (percent == shownPercent) return;
              shownPercent = percent;
              state = state.copyWith(progress: fraction);
            },
          );

      AppLogger.info('Attacks synced', {
        'pushed': outcome.pushed,
        'pulled': outcome.pulled,
      });
      AppAnalytics.logAttacksSynced(
        pushed: outcome.pushed,
        pulled: outcome.pulled,
      );
      // Data is up there that this build cannot read: never expected, and
      // invisible to the user, so it has to reach us some other way.
      if (outcome.unreadable > 0) {
        CrashReporter.recordError(
          StateError('${outcome.unreadable} attack payloads unreadable'),
          StackTrace.current,
          reason: 'Undecryptable synced attacks skipped',
        );
      }
      await _stampSyncedAt(uid);
      state = SyncStatus(lastSyncedAt: DateTime.now());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Attack sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Attack sync failed',
      );
      // Deliberately not rethrown: the next launch, resume or logged attack
      // retries, and nothing on screen was waiting on this.
      state = state.copyWith(phase: SyncPhase.failed, isFirstPull: false);
    }
  }

  /// Whether a pass finished recently enough to skip this one.
  ///
  /// A store that will not answer means no cooldown: syncing once too
  /// often is wasteful, and never syncing is wrong.
  Future<bool> _isCoolingDown(String uid) async {
    try {
      final DateTime? last = await ref
          .read(syncCursorStoreProvider)
          .lastSyncedAt(uid);

      if (last == null) return false;
      return DateTime.now().toUtc().difference(last) < automaticCooldown;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reading the sync cooldown failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Only after a pass that worked: a failure must be retried by the next
  /// open, not held off for another six hours.
  Future<void> _stampSyncedAt(String uid) async {
    try {
      await ref
          .read(syncCursorStoreProvider)
          .saveSyncedAt(uid, DateTime.now().toUtc());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Recording the sync time failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Null rather than throwing: the log flow fires sync straight after saving
  /// an attack, and must not fail because auth is unavailable (hard rule 4).
  AuthUser? _currentUser() {
    try {
      return ref.read(authRepositoryProvider).currentUser;
    } catch (error, stackTrace) {
      AppLogger.error(
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
      AppLogger.error(
        'Reading the sync cursor failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
