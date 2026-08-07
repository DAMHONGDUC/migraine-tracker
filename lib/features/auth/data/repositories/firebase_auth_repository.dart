import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/enums/auth_error.dart';
import '../../domain/enums/auth_provider_kind.dart';
import '../../domain/repositories/auth_repository.dart';

/// Signs in via `linkWithCredential` so the anonymous UID already written
/// to Firestore survives. See [_link] for the one case where it cannot.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._google, this._functions);

  /// Name of the callable that does the server half of account deletion.
  static const String deleteAccountCallable = 'deleteAccount';

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final FirebaseFunctions _functions;

  /// `initialize()` runs once before `authenticate()`; cached so concurrent
  /// taps share the one call.
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
  Future<void> deleteAccount() async {
    // The function deletes the auth user too, so by the time it returns there
    // is nothing left to sign out of — but the local session still holds a
    // stale user until signOut clears it.
    await _functions.httpsCallable(deleteAccountCallable).call<dynamic>();
    await signOut();
  }

  @override
  Future<void> signOut() async {
    // Without this, the next sign-in skips the picker and silently lands back in the account just left.
    try {
      await _google.signOut();
    } on GoogleSignInException {
      // Never signed in with Google on this device — nothing to clear.
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final User? user = _auth.currentUser;

    if (user == null || user.isAnonymous) return;
    await user.updateDisplayName(displayName);
    // userChanges() does not fire for a profile write on its own.
    await user.reload();
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
      // Drop the poisoned future so a retry re-runs instead of awaiting it.
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
    // Apple signs the nonce into the token; without it the token could be replayed.
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

      return OAuthProvider(
        'apple.com',
      ).credential(idToken: identityToken, rawNonce: rawNonce);
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

  /// Upgrades the anonymous session, or signs straight in if there is none.
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
      // - the account already exists, so the anonymous UID can't absorb it — sign into it instead
      // - nothing on-device is lost; Drift is untouched by sign-in
      case 'credential-already-in-use':
      case 'email-already-in-use':
        final UserCredential result = await _auth.signInWithCredential(
          credential,
        );
        return _toDomain(result.user)!;
      // Already linked here — treat as success.
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
          photoUrl: user.photoURL,
        );

  /// 32 cryptographically random bytes, base64url-encoded.
  String _nonce() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return base64UrlEncode(bytes);
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();
}
