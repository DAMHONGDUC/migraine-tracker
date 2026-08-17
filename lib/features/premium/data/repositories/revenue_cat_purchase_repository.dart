import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../domain/entities/premium_offer.dart';
import '../../domain/enums/premium_period.dart';
import '../../domain/enums/purchase_error.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/revenue_cat_client.dart';

/// Buying premium through RevenueCat.
class RevenueCatPurchaseRepository implements PurchaseRepository {
  RevenueCatPurchaseRepository(this._client);

  final RevenueCatClient _client;

  /// The `Package` behind each offer we handed out, by offer id.
  ///
  /// `PremiumOffer` stays a pure domain object — it cannot carry an SDK type
  /// across the layer boundary — so the store's own object is parked here
  /// and looked up again when the user taps buy.
  final Map<String, Package> _packages = <String, Package>{};

  @override
  Future<List<PremiumOffer>> offers() async {
    return _guard(() async {
      await _client.ensureConfigured();

      final Offerings offerings = await Purchases.getOfferings();
      final Offering? offering = AppEnv.revenueCatOffering.isEmpty
          ? offerings.current
          : offerings.all[AppEnv.revenueCatOffering];

      if (offering == null) return const <PremiumOffer>[];

      _packages.clear();

      final List<PremiumOffer> offers = <PremiumOffer>[];

      for (final Package package in offering.availablePackages) {
        final PremiumPeriod? period = _periodOf(package.packageType);

        // Anything the dashboard adds that this app has no row for is skipped, not rendered blind.
        if (period == null) continue;

        _packages[package.identifier] = package;
        offers.add(
          PremiumOffer(
            id: package.identifier,
            period: period,
            priceLabel: package.storeProduct.priceString,
            trialDays: _trialDays(package.storeProduct.introductoryPrice),
          ),
        );
      }
      offers.sort(
        (PremiumOffer a, PremiumOffer b) =>
            a.period.index.compareTo(b.period.index),
      );

      return offers;
    });
  }

  @override
  Future<bool> purchase(PremiumOffer offer) async {
    final Package? package = _packages[offer.id];

    if (package == null) {
      throw const PurchaseException(
        PurchaseError.unknown,
        'No store package for this offer — offers() was never called.',
      );
    }

    return _guard(() async {
      final PurchaseResult result = await Purchases.purchase(
        PurchaseParams.package(package),
      );

      return RevenueCatClient.isEntitled(result.customerInfo);
    });
  }

  @override
  Future<bool> restore() async {
    return _guard(() async {
      await _client.ensureConfigured();

      return RevenueCatClient.isEntitled(await Purchases.restorePurchases());
    });
  }

  @override
  Future<void> identify(String uid) async {
    await _guard(() async {
      await _client.ensureConfigured();
      await Purchases.logIn(uid);
    });
  }

  @override
  Future<void> forget() async {
    await _guard(() async {
      await _client.ensureConfigured();
      await Purchases.logOut();
    });
  }

  /// Runs [action], turning the SDK's `PlatformException` into a domain
  /// [PurchaseException] so nothing above the data layer has to know about
  /// `PurchasesErrorCode`.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error, stackTrace) {
      final PurchaseError mapped = _mapError(
        PurchasesErrorHelper.getErrorCode(error),
      );

      // - Mapping drops the SDK's own code, which is the readable half.
      // - Cancelling is the user's choice, not a failure.
      if (mapped != PurchaseError.cancelled) {
        SdLogger.error(
          LogTagConstant.purchase,
          'RevenueCat call failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      throw PurchaseException(mapped, error.message);
    } on StateError catch (error, stackTrace) {
      // The missing-key throw from RevenueCatClient.apiKey.
      SdLogger.error(
        LogTagConstant.purchase,
        'RevenueCat is not configured',
        error: error,
        stackTrace: stackTrace,
      );

      throw PurchaseException(PurchaseError.notConfigured, error.message);
    }
  }

  PurchaseError _mapError(PurchasesErrorCode code) => switch (code) {
    PurchasesErrorCode.purchaseCancelledError => PurchaseError.cancelled,
    PurchasesErrorCode.networkError ||
    PurchasesErrorCode.offlineConnectionError => PurchaseError.network,
    PurchasesErrorCode.productAlreadyPurchasedError ||
    PurchasesErrorCode.receiptAlreadyInUseError => PurchaseError.alreadyOwned,
    PurchasesErrorCode.paymentPendingError => PurchaseError.pending,
    PurchasesErrorCode.purchaseNotAllowedError => PurchaseError.notAllowed,
    PurchasesErrorCode.configurationError ||
    PurchasesErrorCode.invalidCredentialsError => PurchaseError.notConfigured,
    _ => PurchaseError.unknown,
  };

  PremiumPeriod? _periodOf(PackageType type) => switch (type) {
    PackageType.monthly => PremiumPeriod.monthly,
    PackageType.annual => PremiumPeriod.yearly,
    PackageType.lifetime => PremiumPeriod.lifetime,
    _ => null,
  };

  /// Introductory offers are described as a period + a count of units, so a
  /// "1 month" trial and a "30 day" one arrive differently. Normalize to days
  /// so the paywall has one number to say.
  int? _trialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return null;

    final int units = intro.periodNumberOfUnits;

    return switch (intro.periodUnit) {
      PeriodUnit.day => units,
      PeriodUnit.week => units * 7,
      PeriodUnit.month => units * 30,
      PeriodUnit.year => units * 365,
      PeriodUnit.unknown => null,
    };
  }
}
