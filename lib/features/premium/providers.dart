import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../core/constants/log_tag_constant.dart';
import '../../core/env/app_env.dart';
import '../auth/domain/entities/auth_user.dart';
import '../auth/providers.dart';
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

/// Whether the session belongs to the address [AppEnv.premiumEmail] names —
/// the App Review account, or the owner's own (owner's rule).
///
/// False, and watching nothing, on every build that passes no `PREMIUM_EMAIL`:
/// the key is a compile-time constant, so an unset build cannot take this
/// branch at all, and the gates keep depending on the entitlement alone.
///
/// The address comes from the auth session, which only Google or Apple can
/// write, and both verify it — an anonymous session carries none, so it can
/// never match. Compared case-insensitively and trimmed, because a JSON value
/// typed by hand is where the stray capital and the trailing space live.
final isPremiumEmailProvider = Provider<bool>((ref) {
  final String allowed = AppEnv.premiumEmail.trim().toLowerCase();

  if (allowed.isEmpty) return false;

  final AuthUser? user = switch (ref.watch(authUserProvider)) {
    AsyncData(value: final AuthUser? value) => value,
    _ => ref.watch(authRepositoryProvider).currentUser,
  };
  final bool granted = user?.email?.trim().toLowerCase() == allowed;

  if (granted) {
    SdLogger.info(
      LogTagConstant.premium,
      'Premium granted by PREMIUM_EMAIL build config',
    );
  }

  return granted;
});

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
  // The build's own allow-list, ahead of everything: a reviewer signed in as
  // that address is premium in a prod flavour too, which is the whole point.
  if (ref.watch(isPremiumEmailProvider)) return true;

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
