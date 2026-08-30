import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import '../auth/domain/entities/auth_user.dart';
import '../auth/providers.dart';
import 'data/repositories/firestore_access_repository.dart';
import 'domain/entities/access_grants.dart';
import 'domain/repositories/access_repository.dart';

/// Built only on the signed-in branch of [accessGrantsProvider], so a widget test with an anonymous auth stub never reaches Firestore and never has to override this.
final accessRepositoryProvider = Provider<AccessRepository>(
  (ref) => FirestoreAccessRepository(FirebaseFirestore.instance),
);

/// The address the allow-list would be read for, or empty when there is none.
///
/// Its own provider so the read below depends on the *address* rather than on
/// the auth stream: `authUserProvider` emits twice on a normal launch (the
/// restored session, then the same session again as data), and a provider
/// watching it directly opens two Firestore listeners for one signed-in user.
final _accessEmailProvider = Provider<String>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  // Anonymous sessions carry no address, the rules would deny the read, and
  // the answer is AccessGrants.none either way.
  if (user == null || !user.isSignedIn) return '';

  return user.email?.trim() ?? '';
});

/// What the owner has granted the signed-in address.
final accessGrantsProvider = StreamProvider<AccessGrants>((ref) {
  final String email = ref.watch(_accessEmailProvider);

  if (email.isEmpty) return Stream<AccessGrants>.value(AccessGrants.none);

  return ref.watch(accessRepositoryProvider).watch(email);
});

/// The grants as a plain value. Nothing granted while the read is in flight or after it failed, so a gate never opens on a document the app has not actually seen.
final _grantsProvider = Provider<AccessGrants>(
  (ref) => switch (ref.watch(accessGrantsProvider)) {
    AsyncData(value: final AccessGrants value) => value,
    _ => AccessGrants.none,
  },
);

/// Premium granted by the allow-list rather than bought — the App Review account, and the owner's own (owner's rule). Read by `hasPremiumProvider`, ahead of the entitlement.
final hasAccessPremiumProvider = Provider<bool>(
  (ref) => ref.watch(_grantsProvider).premium,
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
