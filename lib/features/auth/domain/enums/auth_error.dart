/// Why a sign-in attempt did not produce an account. Each value maps to one
/// user-facing message; the raw plugin exceptions never reach the UI.
enum AuthError {
  /// The user backed out of the provider sheet. Not an error to shout about
  /// — the UI stays silent for this one.
  cancelled,

  /// No usable connection, or the provider timed out.
  network,

  /// Sign in with Apple needs iOS 13+; below that the button is hidden and
  /// this only fires if it was reached anyway.
  appleUnavailable,

  /// The provider is offered in the UI but not wired up in this build (see
  /// `appleSignInImplementedProvider`). Distinct from [notConfigured]: that
  /// is a backend that answered no, this is us not having asked yet.
  notImplemented,

  /// The credential is valid but belongs to a Firebase account we could not
  /// attach to this session.
  accountConflict,

  /// The provider is not configured yet (missing CLIENT_ID in
  /// GoogleService-Info.plist, provider disabled in the Firebase console).
  notConfigured,

  unknown,
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthException($error)';
}
