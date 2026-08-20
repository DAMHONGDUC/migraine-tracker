import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
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

  /// Firebase's id for the Apple provider, on `UserInfo.providerId` and on
  /// `OAuthProvider`. One constant so the two cannot drift apart.
  static const String appleProviderId = 'apple.com';

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
    SdLogger.action(LogTagConstant.signIn, 'Sign in', <String, Object?>{
      'provider': provider.name,
    });
    try {
      final AuthCredential credential = switch (provider) {
        AuthProviderKind.google => await _googleCredential(),
        AuthProviderKind.apple => await _appleCredential(),
      };
      final AuthUser user = await _link(credential);

      SdLogger.info(LogTagConstant.signIn, 'Sign in ok', <String, Object?>{
        'provider': provider.name,
        'uid': user.uid,
      });

      return user;
    } on FirebaseAuthException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.signIn,
        'Sign in failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'provider': provider.name,
          'code': error.code,
          'message': error.message,
        },
      );
      rethrow;
    } catch (error, stackTrace) {
      // Cancellation lands here too and is not a failure, but it is worth a
      // line: a sign-in that "did nothing" otherwise looks like a dead button.
      SdLogger.error(
        LogTagConstant.signIn,
        'Sign in failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'provider': provider.name},
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    final String? uid = _auth.currentUser?.uid;

    SdLogger.action(
      LogTagConstant.account,
      'Call $deleteAccountCallable',
      <String, Object?>{'uid': uid},
    );
    try {
      // The function deletes the auth user too, so by the time it returns
      // there is nothing left to sign out of — but the local session still
      // holds a stale user until signOut clears it.
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(deleteAccountCallable)
          .call<dynamic>();

      SdLogger.info(
        LogTagConstant.account,
        '$deleteAccountCallable ok',
        <String, Object?>{'uid': uid, 'response': result.data},
      );
      await signOut();
    } on FirebaseFunctionsException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.account,
        '$deleteAccountCallable failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'uid': uid,
          'code': error.code,
          'message': error.message,
          'details': error.details,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> revokeAppleTokenIfLinked() async {
    final User? user = _auth.currentUser;
    final bool linked =
        user?.providerData.any(
          (UserInfo info) => info.providerId == appleProviderId,
        ) ??
        false;

    // Guarded on the platform as well as the provider: the revoke call is
    // implemented on iOS and macOS only, and an Apple-linked account reached
    // from Android would throw rather than skip.
    if (!linked || (!Platform.isIOS && !Platform.isMacOS)) {
      SdLogger.info(
        LogTagConstant.account,
        'Revoke Apple token skipped',
        <String, Object?>{
          'uid': user?.uid,
          'linked': linked,
          'platform': Platform.operatingSystem,
        },
      );

      return;
    }

    SdLogger.action(
      LogTagConstant.account,
      'Revoke Apple token',
      <String, Object?>{'uid': user!.uid},
    );
    // Outside the try: a cancelled sheet must reach the caller so the deletion
    // stops before anything is wiped, rather than being swallowed as a failed
    // revoke and letting the wipe run.
    final AuthorizationCredentialAppleID credential = await _appleAuthorization(
      LogTagConstant.account,
      _sha256(_nonce()),
    );

    try {
      await _auth.revokeTokenWithAuthorizationCode(
        credential.authorizationCode,
      );
      SdLogger.info(
        LogTagConstant.account,
        'Revoke Apple token ok',
        <String, Object?>{'uid': user.uid},
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      // Swallowed on purpose: a failed revoke must not become the reason a
      // user cannot delete their account — that breaks App Store 5.1.1(v) to
      // satisfy Apple's other rule. Logged loudly, and the deletion carries on.
      SdLogger.error(
        LogTagConstant.account,
        'Revoke Apple token failed, deleting anyway',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'uid': user.uid,
          'code': error.code,
          'message': error.message,
        },
      );
    }
  }

  @override
  Future<void> signOut() async {
    SdLogger.action(LogTagConstant.account, 'Sign out', <String, Object?>{
      'uid': _auth.currentUser?.uid,
    });
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

    if (user == null || user.isAnonymous) {
      SdLogger.warning(
        LogTagConstant.profile,
        'Display name skipped: no account',
      );

      return;
    }

    SdLogger.action(
      LogTagConstant.profile,
      'Update display name',
      <String, Object?>{'uid': user.uid, 'length': displayName.length},
    );
    try {
      await user.updateDisplayName(displayName);
      // userChanges() does not fire for a profile write on its own.
      await user.reload();
      SdLogger.info(
        LogTagConstant.profile,
        'Display name updated',
        <String, Object?>{'uid': user.uid},
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.profile,
        'Update display name failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'uid': user.uid, 'code': error.code},
      );
      rethrow;
    }
  }

  Future<AuthCredential> _googleCredential() async {
    SdLogger.action(LogTagConstant.signIn, 'Google sheet');
    try {
      _googleInit ??= _google.initialize();
      await _googleInit;

      if (!_google.supportsAuthenticate()) {
        SdLogger.error(
          LogTagConstant.signIn,
          'Google sheet unsupported',
          data: <String, Object?>{'platform': Platform.operatingSystem},
        );
        throw const AuthException(AuthError.notConfigured);
      }

      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;

      if (idToken == null) {
        SdLogger.error(LogTagConstant.signIn, 'Google sheet gave no id token');
        throw const AuthException(AuthError.unknown);
      }

      SdLogger.info(
        LogTagConstant.signIn,
        'Google sheet ok',
        _tokenClaims(idToken),
      );

      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error, stackTrace) {
      // Logged before the mapping, not after: the AuthError below keeps the
      // category and throws away the code and description, which are the parts
      // that say what to fix.
      SdLogger.error(
        LogTagConstant.signIn,
        'Google sheet failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'code': error.code.name,
          'description': error.description,
          'details': error.details,
        },
      );
      // Drop the poisoned future so a retry re-runs instead of awaiting it.
      _googleInit = null;
      throw AuthException(switch (error.code) {
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
    final AuthorizationCredentialAppleID credential = await _appleAuthorization(
      LogTagConstant.signIn,
      _sha256(rawNonce),
    );
    final String? identityToken = credential.identityToken;

    if (identityToken == null) {
      SdLogger.error(
        LogTagConstant.signIn,
        'Apple sheet gave no identity token',
      );
      throw const AuthException(AuthError.unknown);
    }

    // The `aud` here is the whole diagnosis of `invalid-credential`: a native
    // sheet signs the token to the app's bundle id, which Firebase accepts
    // only if that id is registered as an iOS app on the project.
    SdLogger.info(
      LogTagConstant.signIn,
      'Apple identity token',
      _tokenClaims(identityToken),
    );

    return OAuthProvider(
      appleProviderId,
    ).credential(idToken: identityToken, rawNonce: rawNonce);
  }

  /// The Apple sheet itself, with its exceptions mapped to [AuthError].
  ///
  /// Shared by signing in and by revoking: revocation needs a fresh
  /// authorization code, and the only way to get one is to ask Apple again.
  ///
  /// [tag] is the caller's flow, not this method's. The same sheet belongs to
  /// signing in one time and to deleting an account the next, and a console
  /// filtered on `Account - ` must show the sheet the deletion opened rather
  /// than lose it under `Sign In`.
  Future<AuthorizationCredentialAppleID> _appleAuthorization(
    String tag,
    String hashedNonce,
  ) async {
    SdLogger.action(tag, 'Apple sheet');
    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );

      // Presence, never the values: an Apple id is the account itself. A null
      // token is why sign-in fails; a null name is why the account has none,
      // Apple sending it only on the first authorization.
      SdLogger.info(tag, 'Apple sheet ok', <String, Object?>{
        'hasIdentityToken': credential.identityToken != null,
        'hasAuthorizationCode': credential.authorizationCode.isNotEmpty,
        'hasEmail': credential.email != null,
        'hasName':
            credential.givenName != null || credential.familyName != null,
      });

      return credential;
    } on SignInWithAppleNotSupportedException catch (error, stackTrace) {
      SdLogger.error(
        tag,
        'Apple sheet unsupported',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'platform': Platform.operatingSystem},
      );
      throw const AuthException(AuthError.appleUnavailable);
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      // `unknown` covers half of `AuthorizationErrorCode` — the code and
      // Apple's own message are the only things that separate them, and the
      // mapping on the next line is where both stop existing.
      SdLogger.error(
        tag,
        'Apple sheet failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'code': error.code.name,
          'message': error.message,
        },
      );
      throw AuthException(switch (error.code) {
        AuthorizationErrorCode.canceled => AuthError.cancelled,
        AuthorizationErrorCode.notHandled ||
        AuthorizationErrorCode.notInteractive => AuthError.network,
        _ => AuthError.unknown,
      });
    } on SignInWithAppleException catch (error, stackTrace) {
      SdLogger.error(
        tag,
        'Apple sheet failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'type': error.runtimeType.toString()},
      );
      throw const AuthException(AuthError.unknown);
    }
  }

  /// Upgrades the anonymous session, or signs straight in if there is none.
  Future<AuthUser> _link(AuthCredential credential) async {
    final User? anonymous = _auth.currentUser;
    final bool upgrading = anonymous != null && anonymous.isAnonymous;

    // Which of the two calls ran decides which Firebase codes are even
    // possible below — `credential-already-in-use` only ever comes from the
    // link, `invalid-credential` from either.
    SdLogger.action(LogTagConstant.signIn, 'Link credential', <String, Object?>{
      'provider': credential.providerId,
      'upgrading': upgrading,
      'uid': anonymous?.uid,
    });
    try {
      final UserCredential result = upgrading
          ? await anonymous.linkWithCredential(credential)
          : await _auth.signInWithCredential(credential);

      SdLogger.info(
        LogTagConstant.signIn,
        'Link credential ok',
        <String, Object?>{
          'uid': result.user?.uid,
          'isNewUser': result.additionalUserInfo?.isNewUser,
          'providers': result.user?.providerData
              .map((UserInfo info) => info.providerId)
              .toList(),
        },
      );

      return _toDomain(result.user)!;
    } on FirebaseAuthException catch (e) {
      return _recoverFromLinkFailure(e, credential);
    }
  }

  Future<AuthUser> _recoverFromLinkFailure(
    FirebaseAuthException e,
    AuthCredential credential,
  ) async {
    // Logged before anything is mapped: every branch below replaces
    // Firebase's code with an AuthError, so without this line the only thing
    // that ever reached the log was "unknown".
    SdLogger.warning(
      LogTagConstant.signIn,
      'Link failed, recovering',
      <String, Object?>{
        'code': e.code,
        'message': e.message,
        'provider': credential.providerId,
      },
    );

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
      // Signed in as someone else already, with a different provider.
      case 'account-exists-with-different-credential':
        throw const AuthException(AuthError.accountConflict);
      case 'network-request-failed':
        throw const AuthException(AuthError.network);
      // All three mean the console side is unfinished: switched off it is
      // `operation-not-allowed`, switched on with no Services ID, Key ID or
      // `.p8` it rejects the token. "unknown" sent readers into the app.
      case 'operation-not-allowed':
      case 'invalid-credential':
      case 'internal-error':
        // Three codes collapse to one AuthError, so the console would show the
        // same word for three different console mistakes. This line keeps them
        // apart by naming what each one means.
        SdLogger.error(
          LogTagConstant.signIn,
          'Provider not configured',
          error: e,
          data: <String, Object?>{
            'code': e.code,
            'provider': credential.providerId,
            'check': switch (e.code) {
              'operation-not-allowed' =>
                'Firebase console > Authentication > Sign-in method: the '
                    'provider is switched off',
              'invalid-credential' =>
                'the token audience: a native Apple sheet signs to the bundle '
                    'id, so that bundle id must be registered as an iOS app on '
                    'this Firebase project',
              _ =>
                'the Apple key: Team ID, Key ID, and a .p8 pasted whole, '
                    'BEGIN and END lines included',
            },
          },
        );
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

  /// The routing claims of an OIDC id token, for the log line only.
  ///
  /// Lives here beside [_nonce] and [_sha256] rather than in a `*Utils`: it
  /// reads one token this repository is holding for the length of one call,
  /// and nothing outside sign-in has an id token to ask about.
  ///
  /// **`aud` and `iss` only, never `sub` or `email`.** Those two say who the
  /// token is for and who signed it, which is the whole question when Firebase
  /// rejects one; the rest identifies a person and has no business in a
  /// console. The signature is not checked — Firebase does that, and this is a
  /// log line, not a gate.
  Map<String, Object?> _tokenClaims(String idToken) {
    final List<String> parts = idToken.split('.');

    if (parts.length != 3) {
      return <String, Object?>{'token': 'unparseable', 'parts': parts.length};
    }

    try {
      final Object? payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map<String, Object?>) {
        return <String, Object?>{'token': 'unparseable'};
      }

      return <String, Object?>{
        'aud': payload['aud'],
        'iss': payload['iss'],
        'hasNonce': payload['nonce'] != null,
      };
    } catch (error, stackTrace) {
      // The caller is building a log line and must not fail because of one:
      // a token this could not read is still a token Firebase may accept.
      SdLogger.error(
        LogTagConstant.signIn,
        'Token claims unreadable',
        error: error,
        stackTrace: stackTrace,
      );

      return <String, Object?>{'token': 'unparseable'};
    }
  }
}
