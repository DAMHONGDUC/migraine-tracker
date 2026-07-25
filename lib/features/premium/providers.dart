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

/// Convenience for widgets/gates. Falls back to the repository's current
/// value while the stream is still loading, so a premium user's gate never
/// flashes locked on the first frame; live toggles come through the stream.
///
/// An entitlement without an account does not unlock anything: a
/// subscription has to belong to something that survives a reinstall, so
/// gates route signed-out users through the login screen first (see
/// [PremiumUnlockFlow]). Both conditions live here rather than at each call
/// site, so no gate can be written that forgets one of them.
final hasPremiumProvider = Provider<bool>((ref) {
  if (!ref.watch(isSignedInProvider)) return false;

  return switch (ref.watch(isPremiumProvider)) {
    AsyncData(value: final bool value) => value,
    _ => ref.watch(premiumRepositoryProvider).isPremium,
  };
});
