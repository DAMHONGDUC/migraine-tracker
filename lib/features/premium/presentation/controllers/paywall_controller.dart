import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/premium_offer.dart';
import '../../domain/enums/purchase_error.dart';
import '../../providers.dart';

/// Loads what can be bought and runs the store flows.
class PaywallController extends AsyncNotifier<List<PremiumOffer>> {
  @override
  Future<List<PremiumOffer>> build() =>
      ref.watch(purchaseRepositoryProvider).offers();

  /// Returns true once the entitlement is active.
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

  /// Re-applies a purchase from another device or a reinstall.
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
