import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
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
    } on AuthException catch (e) {
      state = LoginState(
        error: e.error == AuthError.cancelled ? null : e.error,
      );
      if (e.error != AuthError.cancelled) {
        AppLogger.warning('Sign in failed', e.error.name);
        AppAnalytics.logSignInFailed(
          method: provider.name,
          reason: e.error.name,
        );
      }
      return false;
    }
  }
}

/// Sign-out is triggered from Settings, where [LoginController]'s state
/// machine has no meaning.
class AccountController {
  const AccountController(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    AppLogger.action('Sign out');
    AppAnalytics.logSignOut();
    await _ref.read(authRepositoryProvider).signOut();
  }
}
