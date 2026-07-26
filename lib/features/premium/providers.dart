import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/l10n/locale_provider.dart';
import '../auth/providers.dart';
import 'data/repositories/debug_premium_repository.dart';
import 'domain/repositories/premium_repository.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final repo = DebugPremiumRepository(ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// The single source of truth for gating. Defaults to NOT premium while
/// loading, so a free user never briefly sees a premium surface.
final isPremiumProvider = StreamProvider<bool>(
  (ref) => ref.watch(premiumRepositoryProvider).watchIsPremium(),
);

/// What every gate reads. Falls back to the repository while loading, so a
/// premium gate never flashes locked on the first frame.
///
/// An entitlement without an account unlocks nothing — a subscription needs
/// something that survives a reinstall. Both conditions live here so no
/// gate can forget one.
final hasPremiumProvider = Provider<bool>((ref) {
  if (!ref.watch(isSignedInProvider)) return false;

  return switch (ref.watch(isPremiumProvider)) {
    AsyncData(value: final bool value) => value,
    _ => ref.watch(premiumRepositoryProvider).isPremium,
  };
});
