import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_user_profile_repository.dart';
import 'domain/entities/auth_user.dart';
import 'domain/entities/user_profile.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_profile_repository.dart';
import 'presentation/controllers/auth_controller.dart';

/// Widget tests MUST override this: [authUserProvider] is watched at build
/// time, so a real repository drags Firebase into the test tree.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance, GoogleSignIn.instance),
);

/// Null while Firebase restores it, and after sign-out until something
/// signs in anonymously again.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

/// Widget tests MUST override this too — the account tab watches it.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(FirebaseFirestore.instance),
);

/// The signed-in user's account document. Null when signed out (nothing to
/// read) or before the first write lands.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => null,
  };

  if (user == null || !user.isSignedIn) return Stream<UserProfile?>.value(null);
  return ref.watch(userProfileRepositoryProvider).watch(user.uid);
});

/// Every "needs an account" decision reads this. Falls back to the
/// repository while loading, so Settings never flashes "Sign in".
final isSignedInProvider = Provider<bool>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  return user?.isSignedIn ?? false;
});

/// Whether Sign in with Apple is wired up end to end. False while its Apple
/// Developer setup is outstanding — the button still shows, but tapping it
/// says so instead of running a flow that can only fail.
///
/// MUST be true before submission: a "coming soon" button does not count as
/// offering Apple, which Google obliges us to (App Store 4.8).
final appleSignInImplementedProvider = Provider<bool>((ref) => false);

/// Can the *device* serve Apple sign-in (false on Android, iOS < 13).
/// [appleSignInImplementedProvider] is the separate question of whether *we*
/// have wired it up.
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
