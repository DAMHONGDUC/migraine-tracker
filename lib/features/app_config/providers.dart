import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import '../auth/domain/entities/auth_user.dart';
import '../auth/providers.dart';
import 'data/repositories/firestore_app_config_repository.dart';
import 'domain/entities/app_config.dart';
import 'domain/repositories/app_config_repository.dart';

/// Overridden in every widget test: the document is read with or without a session, so a real repository here would drag Firestore into any tree that gates on premium — which is nearly all of them.
final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => FirestoreAppConfigRepository(FirebaseFirestore.instance),
);

/// The signed-in address, or empty when there is none.
///
/// Its own provider so the gates below rebuild on the *address* rather than on
/// the auth stream: `authUserProvider` emits twice on a normal launch (the
/// restored session, then the same session again as data), and a provider
/// watching it directly rebuilt every gate twice for one signed-in user.
final _configEmailProvider = Provider<String>((ref) {
  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };

  // An anonymous session carries no address, so it is on no list.
  if (user == null || !user.isSignedIn) return '';

  return user.email?.trim() ?? '';
});

/// The live document.
final appConfigProvider = StreamProvider<AppConfig>(
  (ref) => ref.watch(appConfigRepositoryProvider).watch(),
);

/// The document as a plain value. [AppConfig.empty] while the read is in flight or after it failed — premium on, nobody listed. See [AppConfig.empty] for why those two defaults point in opposite directions.
final _configProvider = Provider<AppConfig>(
  (ref) => switch (ref.watch(appConfigProvider)) {
    AsyncData(value: final AppConfig value) => value,
    _ => AppConfig.empty,
  },
);

/// The app-wide premium kill switch. False makes `hasPremiumProvider` answer false for everyone at once — bought, listed, or forced by the Dev group.
final premiumEnabledProvider = Provider<bool>(
  (ref) => ref.watch(_configProvider).premiumEnabled,
);

/// Premium granted by the list rather than bought — the App Review account, and the owner's own (owner's rule). Read by `hasPremiumProvider`, ahead of the entitlement.
final hasGrantedPremiumProvider = Provider<bool>(
  (ref) => ref.watch(_configProvider).isPremium(ref.watch(_configEmailProvider)),
);

/// Whether the signed-in address is locked out. False for an anonymous session, for a read still in flight, and for a read that failed — a list is something an address has to be put on, and a failed read must not lock somebody out of an app whose data is on their own device.
final isAccountBlockedProvider = Provider<bool>(
  (ref) => ref.watch(_configProvider).isBlocked(ref.watch(_configEmailProvider)),
);

/// Whether Settings shows its Dev group.
///
/// A dev flavour always shows it — that is what every build did before any of
/// this existed, and a developer is usually not signed in at all. The list is
/// what adds the group to a **prod** build, which is how a TestFlight tester
/// reaches the fixtures against real Firebase.
final showDevSettingsProvider = Provider<bool>(
  (ref) =>
      !AppEnv.isProd ||
      ref.watch(_configProvider).hasDevMode(ref.watch(_configEmailProvider)),
);
