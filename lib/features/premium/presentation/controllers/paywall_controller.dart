import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../domain/entities/premium_offer.dart';
import '../../domain/enums/purchase_error.dart';
import '../../domain/services/mock_premium_offers.dart';
import '../../providers.dart';

/// Loads what can be bought and runs the store flows.
///
/// Holds only the offers. Whether the user *is* premium stays with
/// `hasPremiumProvider`, fed by the entitlement stream — this controller
/// never decides that, so a bug here cannot unlock anything.
class PaywallController extends AsyncNotifier<List<PremiumOffer>> {
  @override
  Future<List<PremiumOffer>> build() {
    // Dev-only, for App Store screenshots taken before the store products
    // exist. Never true in a prod flavour — see DevMockOffers.
    if (!AppEnv.isProd && ref.watch(devMockOffersProvider)) {
      return Future<List<PremiumOffer>>.value(MockPremiumOffers.all);
    }

    return ref.watch(purchaseRepositoryProvider).offers();
  }

  /// Returns true once the entitlement is active.
  ///
  /// A cancelled purchase is not an error — the user closed Apple's sheet —
  /// so it comes back false and silent, exactly like `AuthError.cancelled`
  /// in [LoginController]. Everything else rethrows for the widget to show.
  Future<bool> purchase(PremiumOffer offer) async {
    SdLogger.action(
      LogTagConstant.paywall,
      'Purchase premium',
      offer.period.name,
    );
    AppAnalytics.logPurchaseStarted(period: offer.period.name);
    try {
      final bool entitled = await ref
          .read(purchaseRepositoryProvider)
          .purchase(offer);

      if (entitled) {
        AppAnalytics.logPurchaseCompleted(period: offer.period.name);
      }

      return entitled;
    } on PurchaseException catch (error, stackTrace) {
      if (error.error == PurchaseError.cancelled) return false;

      SdLogger.error(
        LogTagConstant.paywall,
        'Purchase failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.paywall,
        'Purchase failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Re-applies a purchase from another device or a reinstall. Returns
  /// whether anything came back, so the caller can say "nothing to restore"
  /// rather than leaving the user staring at an unchanged screen.
  Future<bool> restore() async {
    SdLogger.action(LogTagConstant.paywall, 'Restore purchases');
    AppAnalytics.logPurchaseRestored();
    try {
      return await ref.read(purchaseRepositoryProvider).restore();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.paywall,
        'Restore failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Re-reads the offerings — after a sign-in, or a failed first load.
  Future<void> reload() async {
    state = const AsyncLoading<List<PremiumOffer>>();
    state = await AsyncValue.guard(
      () => ref.read(purchaseRepositoryProvider).offers(),
    );
    if (state case AsyncError(
      :final Object error,
      :final StackTrace stackTrace,
    )) {
      SdLogger.error(
        LogTagConstant.paywall,
        'Loading offers failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
