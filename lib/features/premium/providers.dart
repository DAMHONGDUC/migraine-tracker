import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/env/app_env.dart';
import '../app_config/providers.dart';
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

/// Widget tests MUST override this: gates watch it at build time, so a real one would drag the store SDK into every test tree.
final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final RevenueCatPremiumRepository repo = RevenueCatPremiumRepository(
    ref.watch(revenueCatClientProvider),
  );

  ref.onDispose(repo.dispose);

  return repo;
});

/// Only read inside paywall actions, never watched by a gate: buying and being entitled are separate concerns, and only this one can raise a payment sheet.
final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => RevenueCatPurchaseRepository(ref.watch(revenueCatClientProvider)),
);

/// The store page where the subscription is cancelled or changed, or null when the store has nothing to point at. Read only by the manage button, which is why nothing keeps it alive for a free user.
final managementUrlProvider = FutureProvider<String?>(
  // `read`, not `watch`: the purchase repository is a constant, and watching it is what the gate rule warns against.
  (ref) => ref.read(purchaseRepositoryProvider).managementUrl(),
);

/// The single source of truth for gating. Defaults to NOT premium while loading, so a free user never briefly sees a premium surface.
final isPremiumProvider = StreamProvider<bool>(
  (ref) => ref.watch(premiumRepositoryProvider).watchIsPremium(),
);

/// Dev-only forced premium state.
class DevPremiumOverride extends Notifier<bool?> {
  @override
  bool? build() => null;

  /// Forces premium on or off; null hands control back to the entitlement.
  void set(bool? value) => state = value;
}

final devPremiumOverrideProvider = NotifierProvider<DevPremiumOverride, bool?>(
  DevPremiumOverride.new,
);

/// What every gate reads.
final hasPremiumProvider = Provider<bool>((ref) {
  // The kill switch, ahead of everything including the allow-list and the Dev
  // override: `enable_premium: false` means premium does not exist in this
  // build, and a switch a single surface could talk its way past would not be
  // one. Nothing else here can turn premium off for a user who has it, which
  // is why this is the only branch placed above the grant.
  if (!ref.watch(premiumEnabledProvider)) return false;

  // The owner's allow-list, ahead of everything else: a reviewer signed in as that address is premium in a prod flavour too, which is the whole point.
  if (ref.watch(hasGrantedPremiumProvider)) return true;

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

/// The paywall's offers, and the purchase/restore actions over them (see [PaywallController]).
final paywallControllerProvider =
    AsyncNotifierProvider<PaywallController, List<PremiumOffer>>(
      PaywallController.new,
    );

/// Binds purchases to the signed-in account (see [PurchaseIdentity]). Read from the app root's auth listener.
final purchaseIdentityProvider = Provider<PurchaseIdentity>(
  PurchaseIdentity.new,
);
