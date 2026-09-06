import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import '../auth/domain/entities/auth_user.dart';
import '../auth/providers.dart';
import 'data/repositories/firestore_app_config_repository.dart';
import 'domain/entities/app_config_flags.dart';
import 'domain/entities/app_config_grants.dart';
import 'domain/repositories/app_config_repository.dart';

/// Overridden in every widget test: unlike the grants read, [appConfigFlagsProvider] has no signed-in branch to short-circuit on, so a real repository here would drag Firestore into any tree that gates on premium — which is nearly all of them.
final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => FirestoreAppConfigRepository(FirebaseFirestore.instance),
);

/// The address the allow-list would be read for, or empty when there is none.
///
/// Its own provider so the read below depends on the *address* rather than on
/// the auth stream: `authUserProvider` emits twice on a normal launch (the
/// restored session, then the same session again as data), and a provider
/// watching it directly opens two Firestore listeners for one signed-in user.
final _configEmailProvider = Provider<String>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  // Anonymous sessions carry no address, the rules would deny the read, and
  // the answer is AppConfigGrants.none either way.
  if (user == null || !user.isSignedIn) return '';

  return user.email?.trim() ?? '';
});

/// What the owner has granted the signed-in address.
final appConfigGrantsProvider = StreamProvider<AppConfigGrants>((ref) {
  final String email = ref.watch(_configEmailProvider);

  if (email.isEmpty) {
    return Stream<AppConfigGrants>.value(AppConfigGrants.none);
  }

  return ref.watch(appConfigRepositoryProvider).watchGrants(email);
});

/// The switches that apply to everybody. No signed-in branch: a kill switch that only reached signed-in installs would miss almost every user, since the app is fully usable anonymously.
final appConfigFlagsProvider = StreamProvider<AppConfigFlags>(
  (ref) => ref.watch(appConfigRepositoryProvider).watchFlags(),
);

/// The grants as a plain value. Nothing granted while the read is in flight or after it failed, so a gate never opens on a document the app has not actually seen.
final _grantsProvider = Provider<AppConfigGrants>(
  (ref) => switch (ref.watch(appConfigGrantsProvider)) {
    AsyncData(value: final AppConfigGrants value) => value,
    _ => AppConfigGrants.none,
  },
);

/// The flags as a plain value. Everything on while the read is in flight or after it failed — the opposite default to [_grantsProvider], and deliberately so: see [AppConfigFlags].
final _flagsProvider = Provider<AppConfigFlags>(
  (ref) => switch (ref.watch(appConfigFlagsProvider)) {
    AsyncData(value: final AppConfigFlags value) => value,
    _ => AppConfigFlags.allOn,
  },
);

/// Premium granted by the allow-list rather than bought — the App Review account, and the owner's own (owner's rule). Read by `hasPremiumProvider`, ahead of the entitlement.
final hasGrantedPremiumProvider = Provider<bool>(
  (ref) => ref.watch(_grantsProvider).premium,
);

/// The app-wide premium kill switch. False makes `hasPremiumProvider` answer false for everyone at once — bought, allow-listed, or forced by the Dev group.
final premiumEnabledProvider = Provider<bool>(
  (ref) => ref.watch(_flagsProvider).premiumEnabled,
);

/// Whether the signed-in address is locked out. False for an anonymous session, for a read still in flight, and for a read that failed — a lock-out is a grant like any other, and one nobody has been given yet.
final isAccountBlockedProvider = Provider<bool>(
  (ref) => ref.watch(_grantsProvider).blocked,
);

/// Whether Settings shows its Dev group.
///
/// A dev flavour always shows it — that is what every build did before any of
/// this existed, and a developer is usually not signed in at all. The
/// allow-list is what adds the group to a **prod** build, which is how a
/// TestFlight tester reaches the fixtures against real Firebase.
final showDevSettingsProvider = Provider<bool>(
  (ref) => !AppEnv.isProd || ref.watch(_grantsProvider).devSettings,
);
