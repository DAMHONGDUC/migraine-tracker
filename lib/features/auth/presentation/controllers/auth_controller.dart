import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../../medications/providers.dart';
import '../../../settings/providers.dart';
import '../../../sync/providers.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/enums/auth_error.dart';
import '../../domain/enums/auth_provider_kind.dart';
import '../../providers.dart';

/// Login screen state. [error] stays null on cancellation — backing out is not a failure worth reporting.
class LoginState {
  const LoginState({this.pending, this.error});

  /// The open provider sheet, or null when idle. Disables the other button so two sheets cannot race.
  final AuthProviderKind? pending;
  final AuthError? error;

  bool get isBusy => pending != null;
}

/// Owns the login screen's state machine; the repository stays behind it.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// True once the account exists, so the caller can continue.
  Future<bool> signIn(AuthProviderKind provider) async {
    if (state.isBusy) return false;

    // Offered but not wired up: say so, rather than fail with a confusing provider error.
    if (provider == AuthProviderKind.apple &&
        !ref.read(appleSignInImplementedProvider)) {
      state = const LoginState(error: AuthError.notImplemented);
      return false;
    }

    state = LoginState(pending: provider);
    SdLogger.action(LogTagConstant.signIn, 'Sign in', provider.name);

    try {
      await ref.read(authRepositoryProvider).signIn(provider);
      state = const LoginState();
      SdLogger.info(LogTagConstant.signIn, 'Signed in', provider.name);
      AppAnalytics.logLogin(provider.name);
      return true;
    } on AuthException catch (e, stackTrace) {
      state = LoginState(
        error: e.error == AuthError.cancelled ? null : e.error,
      );
      // Backing out is not a failure — only real ones get logged.
      if (e.error != AuthError.cancelled) {
        SdLogger.error(
          LogTagConstant.signIn,
          'Sign in failed (${e.error.name})',
          error: e,
          stackTrace: stackTrace,
        );
        AppAnalytics.logSignInFailed(
          method: provider.name,
          reason: e.error.name,
        );
      }
      return false;
    } catch (error, stackTrace) {
      // Anything not mapped to an AuthException has no UI state, but must not vanish from the console.
      SdLogger.error(
        LogTagConstant.signIn,
        'Sign in crashed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// The account itself — sign-out and the profile document.
class AccountController {
  const AccountController(this._ref);

  final Ref _ref;

  /// Hands this device's records back to the account and empties the device. False when they could not all be handed back — and then nothing was touched.
  ///
  /// The order is the whole rule, and each step is why the one before it
  /// exists:
  ///
  /// 1. **Push what is still owed.** Every other push in the app is
  ///    fire-and-forget because a later one retries it. This is the last one
  ///    there will ever be, so it is the only push whose answer is read.
  /// 2. **Wipe the device's copy, never the server's.** The records are being
  ///    handed back to the account, not deleted.
  /// 3. **Drop the account's sync state.** The cursor points past everything
  ///    step 2 just removed; left in place, signing back in would pull only
  ///    what changed since, and the history would never come home.
  /// 4. **Sign out**, which fires the listener that clears the rest.
  Future<bool> signOut() async {
    SdLogger.action(LogTagConstant.account, 'Sign out');

    final bool flushed = await _ref
        .read(syncControllerProvider.notifier)
        .flushPending();

    if (!flushed) {
      // Already logged with its error where it failed. This line is the decision, which that one cannot see.
      SdLogger.warning(
        LogTagConstant.account,
        'Sign out stopped — records are still owed to the server',
      );

      return false;
    }
    await _ref.read(dataWipeServiceProvider).wipeLocal();
    await _ref.read(syncControllerProvider.notifier).onSignedOut();
    AppAnalytics.logSignOut();
    await _ref.read(authRepositoryProvider).signOut();

    return true;
  }

  /// Deletes the account, everything the backend held about it, and this device's copy (App Store 5.1.1(v)).
  Future<void> deleteAccount() async {
    SdLogger.action(LogTagConstant.account, 'Delete account');
    try {
      // Apple first, and before the wipe: it re-opens the Apple sheet, so it is the one step the user can still back out of.
      await _ref.read(authRepositoryProvider).revokeAppleTokenIfLinked();
      await _ref.read(dataWipeServiceProvider).wipeAll();
      await _ref.read(authRepositoryProvider).deleteAccount();
      AppAnalytics.logAccountDeleted();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.account,
        'Delete account failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Pushes what the auth provider knows into `users/{uid}`, and seeds what a
  /// brand-new account starts with.
  ///
  /// The write is what knows the account is new — it is the one read that can
  /// tell "signed in for the first time ever" from "signed in again on this
  /// device" — so the first-run seeding hangs off it rather than off a second
  /// flag the app would have to keep in step.
  Future<void> syncProfile(AuthUser user) async {
    if (!user.isSignedIn) return;

    try {
      final bool created = await _ref
          .read(userProfileRepositoryProvider)
          .upsertFromAccount(user);

      SdLogger.info(LogTagConstant.profile, 'Profile synced', <String, Object?>{
        'uid': user.uid,
        'created': created,
      });
      if (created) {
        await _ref.read(defaultMedicationSeederProvider).seedIfEmpty();
      }
    } catch (error, stackTrace) {
      SdLogger.warning(LogTagConstant.profile, 'Profile sync failed', error);
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'User profile sync failed',
      );
    }
  }

  /// Renames the account.
  Future<void> updateDisplayName(String displayName) async {
    final AuthUser? user = _ref.read(authRepositoryProvider).currentUser;
    final String trimmed = displayName.trim();

    if (user == null || !user.isSignedIn || trimmed.isEmpty) return;
    SdLogger.action(LogTagConstant.profile, 'Update display name');
    AppAnalytics.logProfileNameUpdated();
    await _ref
        .read(userProfileRepositoryProvider)
        .updateDisplayName(uid: user.uid, displayName: trimmed);
    await _ref.read(authRepositoryProvider).updateDisplayName(trimmed);
  }
}
