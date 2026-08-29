import 'package:meta/meta.dart';

/// The account behind the current session. Anonymous is still a real UID (alert registration uses it); [isSignedIn] is what gating cares about.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;

  /// Null when withheld — Apple only sends the profile on first sign-in.
  final String? email;
  final String? displayName;

  /// Provider avatar (Google). Null for Apple and for anonymous sessions.
  final String? photoUrl;

  bool get isSignedIn => !isAnonymous;

  /// Account row label. Null → the UI shows "signed in", never the UID.
  String? get label => email ?? displayName;
}
