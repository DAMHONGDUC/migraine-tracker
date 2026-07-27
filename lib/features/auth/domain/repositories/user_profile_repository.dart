import '../entities/auth_user.dart';
import '../entities/user_profile.dart';

/// The signed-in user's own account document. Every method is scoped to one
/// uid — the Firestore rules allow nothing else.
abstract interface class UserProfileRepository {
  /// Live profile, so an edit made here (or on another device) lands on the
  /// account screen without a refresh. Null while the document does not
  /// exist yet.
  Stream<UserProfile?> watch(String uid);

  /// Creates or refreshes the record from what the auth provider gave us.
  /// Called on sign-in and on every launch of a signed-in session, so the
  /// account stays in step with the provider (a changed Google avatar, an
  /// email that Apple only revealed on first sign-in).
  ///
  /// Never overwrites a [UserProfile.displayName] the user typed here.
  Future<void> upsertFromAccount(AuthUser user);

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });
}
