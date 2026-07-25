import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/enums/auth_error.dart';
import '../../domain/enums/auth_provider_kind.dart';
import '../../providers.dart';

/// View state of the login screen. [error] is null while nothing has gone
/// wrong; a cancelled sheet clears it rather than reporting it — backing out
/// is not a failure the user needs told about.
class LoginState {
  const LoginState({this.pending, this.error});

  /// The provider whose sheet is open, or null when idle. Drives the spinner
  /// and disables the other button so two sheets can never race.
  final AuthProviderKind? pending;
  final AuthError? error;

  bool get isBusy => pending != null;
}

/// Owns the login screen's state machine. The screen only renders this and
/// calls [signIn]; the repository stays behind the controller.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Returns true once the account exists, so the caller can continue what
  /// it was doing (pop back to Settings, or move on to the paywall).
  Future<bool> signIn(AuthProviderKind provider) async {
    if (state.isBusy) return false;

    state = LoginState(pending: provider);
    AppLogger.action('Sign in', provider.name);

    try {
      await ref.read(authRepositoryProvider).signIn(provider);
      state = const LoginState();
      AppLogger.info('Signed in', provider.name);
      return true;
    } on AuthException catch (e) {
      state = LoginState(
        error: e.error == AuthError.cancelled ? null : e.error,
      );
      if (e.error != AuthError.cancelled) {
        AppLogger.warning('Sign in failed', e.error.name);
      }
      return false;
    }
  }
}

/// Sign-out lives apart from [LoginController]: it is triggered from
/// Settings, where the login screen's state machine has no meaning.
class AccountController {
  const AccountController(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    AppLogger.action('Sign out');
    await _ref.read(authRepositoryProvider).signOut();
  }
}
