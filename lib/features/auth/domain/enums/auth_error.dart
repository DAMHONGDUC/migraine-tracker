/// Why sign-in produced no account. One user-facing message each; raw
/// plugin exceptions never reach the UI.
enum AuthError {
  /// Backed out of the provider sheet — the UI stays silent for this one.
  cancelled,

  /// No usable connection, or the provider timed out.
  network,

  /// Apple needs iOS 13+. The button is hidden below that anyway.
  appleUnavailable,

  /// Offered in the UI, not wired up yet (`appleSignInImplementedProvider`).
  /// Unlike [notConfigured], we never even asked the backend.
  notImplemented,

  /// Valid credential, but its account cannot attach to this session.
  accountConflict,

  /// Backend not set up: missing CLIENT_ID, or provider off in Firebase.
  notConfigured,

  unknown,
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthException($error)';
}
