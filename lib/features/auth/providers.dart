import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'domain/entities/auth_user.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/controllers/auth_controller.dart';

/// Widget tests MUST override this: unlike the alerts repository (only ever
/// read inside controller actions), [authUserProvider] is watched at build
/// time by Settings and by every premium gate, so leaving it real would drag
/// Firebase into the test tree.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance, GoogleSignIn.instance),
);

/// The live session. Null while Firebase restores it, and again after a
/// sign-out until some feature signs in anonymously.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

/// The gate every "needs an account" decision reads. Defaults to false while
/// the stream is still loading, falling back to the repository's current
/// value so a signed-in user's Settings row does not flash "Sign in".
final isSignedInProvider = Provider<bool>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  return user?.isSignedIn ?? false;
});

/// Whether Sign in with Apple is wired up end to end.
///
/// False while its Apple Developer setup (Services ID, .p8 key, App ID
/// capability) is outstanding. The button still shows — the login screen is
/// built in its final shape — but tapping it says so plainly instead of
/// running a flow that can only fail. [FirebaseAuthRepository] already
/// implements the whole thing; this is the only line to flip.
///
/// MUST be true before App Store submission: offering Google sign-in makes
/// Sign in with Apple mandatory (App Store 4.8), and a button that answers
/// "coming soon" does not count as offering it.
final appleSignInImplementedProvider = Provider<bool>((ref) => false);

/// Whether the platform can serve Sign in with Apple at all — false on
/// Android and on iOS older than 13. Independent of
/// [appleSignInImplementedProvider]: this one is about the device, that one
/// is about us. The button is hidden only where the platform rules it out.
final isAppleSignInAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isAppleAvailable(),
);

/// Owns the login screen's state machine (see [LoginController]).
final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

/// Sign-out, triggered from Settings (see [AccountController]).
final accountControllerProvider = Provider<AccountController>(
  AccountController.new,
);
