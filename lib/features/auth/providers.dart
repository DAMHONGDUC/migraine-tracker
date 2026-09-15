import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/utils/string_utils.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_user_profile_repository.dart';
import 'domain/entities/auth_user.dart';
import 'domain/entities/user_profile.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_profile_repository.dart';
import 'presentation/controllers/auth_controller.dart';

/// Widget tests MUST override this: [authUserProvider] is watched at build time, so a real repository drags Firebase into the test tree.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn.instance,
    // Same region as the functions themselves; the default would miss them.
    FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion),
  ),
);

/// Null while Firebase restores it, and after sign-out until something signs in anonymously again.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

/// Widget tests MUST override this too — the account tab watches it.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(FirebaseFirestore.instance),
);

/// The signed-in user's account document. Null when signed out (nothing to read) or before the first write lands.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => null,
  };

  if (user == null || !user.isSignedIn) return Stream<UserProfile?>.value(null);
  return ref.watch(userProfileRepositoryProvider).watch(user.uid);
});

/// The signed-in account's first name, or null when there is no account or no name on it.
///
/// The profile document wins over the provider: it is the one the user can
/// edit, so a name typed in the account screen must be the name the app greets
/// them by. The email is deliberately not a fallback — a local part is an
/// address, and "Hi, ducdam.dev" reads as a mail merge.
final firstNameProvider = Provider<String?>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => null,
  };

  if (user == null || !user.isSignedIn) return null;

  final UserProfile? profile = switch (ref.watch(userProfileProvider)) {
    AsyncData(value: final UserProfile? value) => value,
    _ => null,
  };

  return StringUtils.firstName(profile?.displayName) ??
      StringUtils.firstName(user.displayName);
});

/// Every "needs an account" decision reads this. Falls back to the repository while loading, so Settings never flashes "Sign in".
final isSignedInProvider = Provider<bool>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  return user?.isSignedIn ?? false;
});

/// Whether Sign in with Apple is wired up end to end.
final appleSignInImplementedProvider = Provider<bool>((ref) => true);

/// Can the *device* serve Apple sign-in (false on Android, iOS < 13).
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
