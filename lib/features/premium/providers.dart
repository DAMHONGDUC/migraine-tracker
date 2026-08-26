import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import 'data/datasources/revenue_cat_client.dart';
import 'data/repositories/revenue_cat_premium_repository.dart';
import 'data/repositories/revenue_cat_purchase_repository.dart';
import 'domain/entities/premium_offer.dart';
import 'domain/repositories/premium_repository.dart';
import 'domain/repositories/purchase_repository.dart';
import 'presentation/controllers/paywall_controller.dart';
import 'presentation/controllers/purchase_identity.dart';

/// Shared by both premium repositories so the SDK is configured exactly once.
final revenueCatClientProvider = Provider<RevenueCatClient>(
  (ref) => RevenueCatClient(),
);

/// Widget tests MUST override this: gates watch it at build time, so a real
/// one would drag the store SDK into every test tree.
final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final RevenueCatPremiumRepository repo = RevenueCatPremiumRepository(
    ref.watch(revenueCatClientProvider),
  );

  ref.onDispose(repo.dispose);

  return repo;
});

/// Only read inside paywall actions, never watched by a gate: buying and
/// being entitled are separate concerns, and only this one can raise a
/// payment sheet.
final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => RevenueCatPurchaseRepository(ref.watch(revenueCatClientProvider)),
);

/// The single source of truth for gating. Defaults to NOT premium while
/// loading, so a free user never briefly sees a premium surface.
final isPremiumProvider = StreamProvider<bool>(
  (ref) => ref.watch(premiumRepositoryProvider).watchIsPremium(),
);

/// Dev-only forced premium state. Null means "follow RevenueCat", which is
/// what it is until a developer flips the Settings toggle.
///
/// CLAUDE.md deleted the old `DebugPremiumRepository` because a premium state
/// the client can *write* is the one thing this project must not ship. This
/// is deliberately not that: it holds no repository, writes nothing to disk,
/// and lives only in memory for the run. [hasPremiumProvider] reads it behind
/// `!AppEnv.isProd`, so in a prod flavour the branch can never be taken and
/// the only answer is RevenueCat's.
class DevPremiumOverride extends Notifier<bool?> {
  @override
  bool? build() => null;

  /// Forces premium on or off; null hands control back to the entitlement.
  void set(bool? value) => state = value;
}

final devPremiumOverrideProvider = NotifierProvider<DevPremiumOverride, bool?>(
  DevPremiumOverride.new,
);

/// What every gate reads. Falls back to the repository while loading, so a
/// premium gate never flashes locked on the first frame.
///
/// **The entitlement is the whole answer — an account is never part of it.**
/// It used to also require a signed-in user, on the reasoning that a
/// subscription needs something that survives a reinstall. App Store 5.1.1(v)
/// says otherwise, and submission 1.0(20) was rejected for it: premium here is
/// not account-based content, so registration cannot be its price. A reinstall
/// is what "Restore purchases" is for, and signing in is offered on the
/// paywall as what carries the subscription to a second device.
final hasPremiumProvider = Provider<bool>((ref) {
  // Never true in a prod flavour — see DevPremiumOverride.
  if (!AppEnv.isProd) {
    final bool? forced = ref.watch(devPremiumOverrideProvider);

    if (forced != null) return forced;
  }

  return switch (ref.watch(isPremiumProvider)) {
    AsyncData(value: final bool value) => value,
    _ => ref.watch(premiumRepositoryProvider).isPremium,
  };
});

/// The paywall's offers, and the purchase/restore actions over them (see
/// [PaywallController]).
final paywallControllerProvider =
    AsyncNotifierProvider<PaywallController, List<PremiumOffer>>(
      PaywallController.new,
    );

/// Binds purchases to the signed-in account (see [PurchaseIdentity]). Read
/// from the app root's auth listener.
final purchaseIdentityProvider = Provider<PurchaseIdentity>(
  PurchaseIdentity.new,
);
