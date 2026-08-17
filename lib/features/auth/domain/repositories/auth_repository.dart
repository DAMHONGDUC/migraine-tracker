import '../entities/auth_user.dart';
import '../enums/auth_provider_kind.dart';

/// The optional account. Everything works without one (hard rule 1);
/// signing in only unlocks the subscription.
abstract interface class AuthRepository {
  /// Null until Firebase restores or creates a session.
  AuthUser? get currentUser;

  /// Emits on every sign-in, sign-out and anonymous upgrade.
  Stream<AuthUser?> watchUser();

  /// False on Android and iOS < 13 — hide the button rather than break it.
  Future<bool> isAppleAvailable();

  /// Upgrades the anonymous UID rather than replacing it.
  /// Throws [AuthException] on every failure, cancellation included.
  Future<AuthUser> signIn(AuthProviderKind provider);

  /// The app stays usable: the next feature needing a UID goes anonymous.
  Future<void> signOut();

  /// Renames the account on the auth record itself, so a reinstall or a
  /// second device sees the name the user chose. No-op when signed out.
  Future<void> updateDisplayName(String displayName);

  /// Deletes the account and everything the backend holds about it, then
  /// leaves the app signed out.
  ///
  /// The server half runs in a Cloud Function: `firestore.rules` denies a
  /// client deleting `users/{uid}` and denies `sync_keys/{uid}` to everyone,
  /// so this could never have been done from here. Local data is the
  /// caller's job — see `DataWipeService`.
  ///
  /// App Store 5.1.1(v) requires this to exist in-app once accounts do.
  Future<void> deleteAccount();

  /// Tells Apple to forget the app, ahead of [deleteAccount]. No-op unless
  /// Apple is one of the account's linked providers.
  ///
  /// Apple requires an app offering Sign in with Apple to revoke its token
  /// when the account is deleted; without it the user is still listed under
  /// Settings → Apple ID → Sign in with Apple, and "deleted" is not what
  /// happened. Revoking needs a **fresh** authorization code, and the one
  /// from signing in was single-use and is long gone — so this re-runs the
  /// Apple sheet, which doubles as the re-authentication a destructive
  /// action deserves.
  ///
  /// **Call it before wiping anything**, never after. Cancelling the Apple
  /// sheet throws [AuthError.cancelled], and a cancel that arrives after the
  /// device has been wiped costs the user their records while leaving the
  /// account standing.
  Future<void> revokeAppleTokenIfLinked();
}
