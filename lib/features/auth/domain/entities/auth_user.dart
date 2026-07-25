import 'package:meta/meta.dart';

/// The account behind the current session.
///
/// An anonymous user is still a real Firebase UID — it is what alert
/// registration already uses, and hard rule 1 keeps the app fully usable in
/// that state. The distinction that matters for gating is [isSignedIn]: the
/// anonymous UID was upgraded with a Google/Apple credential, so purchases
/// have something durable to hang off.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isAnonymous;

  /// Null when the provider withheld it — Sign in with Apple's "Hide My
  /// Email" returns a relay address, and a returning Apple user returns
  /// nothing at all (Apple only sends the profile on first authorization).
  final String? email;
  final String? displayName;

  bool get isSignedIn => !isAnonymous;

  /// What Settings shows under the account row. Null when the provider gave
  /// us neither — the UI falls back to a generic "signed in" label rather
  /// than exposing the raw UID.
  String? get label => email ?? displayName;
}
