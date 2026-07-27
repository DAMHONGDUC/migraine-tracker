import 'package:hooks_riverpod/hooks_riverpod.dart';

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

/// Sign-out is triggered from Settings, where [LoginController]'s state
/// machine has no meaning.
class AccountController {
  const AccountController(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    AppLogger.action('Sign out');
    await _ref.read(authRepositoryProvider).signOut();
  }
}
