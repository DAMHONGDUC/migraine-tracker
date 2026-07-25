import '../entities/auth_user.dart';
import '../enums/auth_provider_kind.dart';

/// Contract for the optional account. Everything above this line works
/// without one (hard rule 1) — signing in only unlocks the subscription and,
/// later, cloud sync.
abstract interface class AuthRepository {
  /// The session as it stands right now, or null when Firebase has not
  /// restored (or created) one yet.
  AuthUser? get currentUser;

  /// Emits on every sign-in, sign-out and anonymous upgrade.
  Stream<AuthUser?> watchUser();

  /// False on Android and on iOS older than 13 — the Apple button is hidden
  /// rather than shown broken.
  Future<bool> isAppleAvailable();

  /// Upgrades the current anonymous UID with [provider]'s credential, so the
  /// UID survives the sign-in instead of being replaced.
  ///
  /// Throws [AuthException] for every failure path, including cancellation.
  Future<AuthUser> signIn(AuthProviderKind provider);

  /// Drops the account. The app stays fully usable afterwards — the next
  /// feature that needs a UID signs in anonymously again.
  Future<void> signOut();
}
