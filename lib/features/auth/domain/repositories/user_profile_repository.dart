import '../entities/auth_user.dart';
import '../entities/user_profile.dart';

/// The signed-in user's own account document. Every method is scoped to one uid — the Firestore rules allow nothing else.
abstract interface class UserProfileRepository {
  /// Live profile, so an edit made here (or on another device) lands on the account screen without a refresh. Null while the document does not exist yet.
  Stream<UserProfile?> watch(String uid);

  /// Creates or refreshes the record from what the auth provider gave us.
  ///
  /// True only when this call is what brought the document into existence —
  /// the app's one definition of "this account has just been created", which
  /// the first-run seeding reads (see `AccountController.syncProfile`).
  Future<bool> upsertFromAccount(AuthUser user);

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });
}
