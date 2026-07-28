import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/enums/auth_error.dart';
import '../../domain/enums/auth_provider_kind.dart';
import '../../providers.dart';

/// Login screen state. [error] stays null on cancellation — backing out is
/// not a failure worth reporting.
class LoginState {
  const LoginState({this.pending, this.error});

  /// The open provider sheet, or null when idle. Disables the other button
  /// so two sheets cannot race.
  final AuthProviderKind? pending;
  final AuthError? error;

  bool get isBusy => pending != null;
}

/// Owns the login screen's state machine; the repository stays behind it.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// True once the account exists, so the caller can continue.
  Future<bool> signIn(AuthProviderKind provider) async {
    if (state.isBusy) return false;

    // Offered but not wired up: say so, rather than start a flow that can
    // only end in a confusing provider error.
    if (provider == AuthProviderKind.apple &&
        !ref.read(appleSignInImplementedProvider)) {
      state = const LoginState(error: AuthError.notImplemented);
      return false;
    }

    state = LoginState(pending: provider);
    AppLogger.action('Sign in', provider.name);

    try {
      await ref.read(authRepositoryProvider).signIn(provider);
      state = const LoginState();
      AppLogger.info('Signed in', provider.name);
      AppAnalytics.logLogin(provider.name);
      return true;
    } on AuthException catch (e, stackTrace) {
      state = LoginState(
        error: e.error == AuthError.cancelled ? null : e.error,
      );
      // Backing out is not a failure — only real ones get logged.
      if (e.error != AuthError.cancelled) {
        AppLogger.error(
          'Sign in failed (${e.error.name})',
          error: e,
          stackTrace: stackTrace,
        );
        AppAnalytics.logSignInFailed(
          method: provider.name,
          reason: e.error.name,
        );
      }
      return false;
    } catch (error, stackTrace) {
      // Anything the repository didn't map to an AuthException: no UI state
      // fits it, but it must not vanish from the console.
      AppLogger.error('Sign in crashed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// The account itself — sign-out and the profile document. Separate from
/// [LoginController], whose state machine only means anything while the
/// login screen is up.
class AccountController {
  const AccountController(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    AppLogger.action('Sign out');
    AppAnalytics.logSignOut();
    await _ref.read(authRepositoryProvider).signOut();
  }

  /// Pushes what the auth provider knows into `users/{uid}`. Called on
  /// sign-in and on each launch of a signed-in session.
  ///
  /// Best-effort: an account record that failed to write is not worth
  /// blocking anyone over, and the next launch retries it.
  Future<void> syncProfile(AuthUser user) async {
    if (!user.isSignedIn) return;

    try {
      await _ref.read(userProfileRepositoryProvider).upsertFromAccount(user);
      AppLogger.info('Profile synced', user.uid);
    } catch (error, stackTrace) {
      AppLogger.warning('Profile sync failed', error);
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'User profile sync failed',
      );
    }
  }

  /// Renames the account. Writes Firestore first — that is what the app
  /// reads back — then the Firebase Auth profile, so a second device that
  /// only has the auth record shows the same name.
  Future<void> updateDisplayName(String displayName) async {
    final AuthUser? user = _ref.read(authRepositoryProvider).currentUser;
    final String trimmed = displayName.trim();

    if (user == null || !user.isSignedIn || trimmed.isEmpty) return;
    AppLogger.action('Update display name');
    AppAnalytics.logProfileNameUpdated();
    await _ref
        .read(userProfileRepositoryProvider)
        .updateDisplayName(uid: user.uid, displayName: trimmed);
    await _ref.read(authRepositoryProvider).updateDisplayName(trimmed);
  }
}
