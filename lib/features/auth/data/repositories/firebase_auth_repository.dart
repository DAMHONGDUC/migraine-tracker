import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/enums/auth_error.dart';
import '../../domain/enums/auth_provider_kind.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase-backed [AuthRepository].
///
/// Sign-in always goes through `linkWithCredential` on the current anonymous
/// user, so the UID that alert registration already wrote to Firestore is
/// upgraded rather than replaced. The one case where that is impossible —
/// the credential already belongs to another Firebase account — falls back
/// to a plain sign-in, documented at [_link].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// `initialize()` must run exactly once before `authenticate()`, and it is
  /// async — cached so concurrent taps share the one call.
  Future<void>? _googleInit;

  @override
  AuthUser? get currentUser => _toDomain(_auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() => _auth.userChanges().map(_toDomain);

  @override
  Future<bool> isAppleAvailable() {
    if (!Platform.isIOS && !Platform.isMacOS) return Future<bool>.value(false);

    return SignInWithApple.isAvailable();
  }

  @override
  Future<AuthUser> signIn(AuthProviderKind provider) async {
    final AuthCredential credential = switch (provider) {
      AuthProviderKind.google => await _googleCredential(),
      AuthProviderKind.apple => await _appleCredential(),
    };

    return _link(credential);
  }

  @override
  Future<void> signOut() async {
    // Google keeps its own session: without this the account picker is
    // skipped on the next sign-in and the user silently lands back in the
    // account they just left.
    try {
      await _google.signOut();
    } on GoogleSignInException {
      // Never signed in with Google on this device — nothing to clear.
    }
    await _auth.signOut();
  }

  Future<AuthCredential> _googleCredential() async {
    try {
      _googleInit ??= _google.initialize();
      await _googleInit;

      if (!_google.supportsAuthenticate()) {
        throw const AuthException(AuthError.notConfigured);
      }

      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException(AuthError.unknown);

      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // The cached initialize() future is poisoned once it fails (a missing
      // CLIENT_ID does not fix itself mid-session, but a retry should at
      // least re-run rather than await a dead future).
      _googleInit = null;
      throw AuthException(switch (e.code) {
        GoogleSignInExceptionCode.canceled => AuthError.cancelled,
        GoogleSignInExceptionCode.interrupted => AuthError.network,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthError.notConfigured,
        _ => AuthError.unknown,
      });
    }
  }

  Future<AuthCredential> _appleCredential() async {
    // Apple signs the raw nonce into the identity token; Firebase re-hashes
    // the raw value and compares. Without it the same token could be
    // replayed against our project.
    final String rawNonce = _nonce();

    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: _sha256(rawNonce),
          );
      final String? identityToken = credential.identityToken;
      if (identityToken == null) throw const AuthException(AuthError.unknown);

      return OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleNotSupportedException {
      throw const AuthException(AuthError.appleUnavailable);
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthException(switch (e.code) {
        AuthorizationErrorCode.canceled => AuthError.cancelled,
        AuthorizationErrorCode.notHandled ||
        AuthorizationErrorCode.notInteractive => AuthError.network,
        _ => AuthError.unknown,
      });
    } on SignInWithAppleException {
      throw const AuthException(AuthError.unknown);
    }
  }

  /// Upgrades the anonymous session, or signs straight in when there is no
  /// session to upgrade.
  Future<AuthUser> _link(AuthCredential credential) async {
    final User? anonymous = _auth.currentUser;

    try {
      final UserCredential result = anonymous == null || !anonymous.isAnonymous
          ? await _auth.signInWithCredential(credential)
          : await anonymous.linkWithCredential(credential);

      return _toDomain(result.user)!;
    } on FirebaseAuthException catch (e) {
      return _recoverFromLinkFailure(e, credential);
    }
  }

  Future<AuthUser> _recoverFromLinkFailure(
    FirebaseAuthException e,
    AuthCredential credential,
  ) async {
    switch (e.code) {
      // The Google/Apple account is already a Firebase user of its own —
      // the anonymous UID cannot absorb it. Signing in with the existing
      // account is the only way through, and it is the right one: the user
      // asked for THAT account. Nothing on-device is lost (Drift is the
      // source of truth and is untouched by sign-in); the abandoned
      // anonymous UID's alert registration is dealt with when sync lands.
      case 'credential-already-in-use':
      case 'email-already-in-use':
        final UserCredential result = await _auth.signInWithCredential(
          credential,
        );
        return _toDomain(result.user)!;
      // Already linked to this very session — treat as success.
      case 'provider-already-linked':
        final AuthUser? user = currentUser;
        if (user != null) return user;
        throw const AuthException(AuthError.accountConflict);
      case 'network-request-failed':
        throw const AuthException(AuthError.network);
      case 'operation-not-allowed':
        throw const AuthException(AuthError.notConfigured);
      default:
        throw const AuthException(AuthError.unknown);
    }
  }

  AuthUser? _toDomain(User? user) => user == null
      ? null
      : AuthUser(
          uid: user.uid,
          isAnonymous: user.isAnonymous,
          email: user.email,
          displayName: user.displayName,
        );

  /// 32 cryptographically random bytes, base64url-encoded.
  String _nonce() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
