import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/providers.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/entities/sync_status.dart';
import '../../providers.dart';

/// Runs attack sync and holds the only state the UI may see.
///
/// Never throws to its callers: every trigger fires it unawaited and no
/// screen waits on it (hard rule 12), so a failure is logged and left for the
/// next pass rather than surfaced as an error the user must dismiss.
class SyncController extends Notifier<SyncStatus> {
  Future<void>? _inFlight;

  @override
  SyncStatus build() => const SyncStatus();

  /// Syncs the signed-in account, if there is one.
  ///
  /// Concurrent calls join the running pass instead of starting a second: the
  /// launch, resume and after-logging triggers all overlap in normal use, and
  /// two passes at once would push the same records twice.
  Future<void> sync() async {
    final AuthUser? user = _currentUser();

    if (user == null || !user.isSignedIn) return;
    return _inFlight ??= _run(user.uid).whenComplete(() => _inFlight = null);
  }

  /// Clears the account's sync state on sign-out. Local attacks stay — they
  /// are the source of truth, and signing out is not a delete.
  Future<void> onSignedOut() async {
    state = const SyncStatus();
    try {
      await ref.read(attackSyncServiceProvider).onSignedOut();
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

    state = state.copyWith(phase: SyncPhase.syncing, isFirstPull: isFirstPull);
    try {
      final SyncOutcome outcome = await ref
          .read(attackSyncServiceProvider)
          .sync(uid);

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
      return await ref.read(attackSyncServiceProvider).isFirstPull(uid);
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
