import '../entities/premium_offer.dart';
import '../enums/premium_period.dart';

/// The three plans at the prices `PLAN.md` sets, so the paywall can be
/// screenshotted for the App Store before the store products exist.
///
/// **Dev-only, and it has to stay that way.** These prices are assembled in
/// Dart, which is the one thing [PremiumOffer.priceLabel] exists to prevent —
/// a real storefront formats its own currency, separator and placement, and a
/// hardcoded `$4.99` is wrong everywhere outside the US. Reachable only
/// through `devMockOffersProvider`, which is behind `!AppEnv.isProd`.
///
/// The ids are `mock_` prefixed so a purchase attempted against one cannot be
/// mistaken for a real package by anything reading logs.
final class MockPremiumOffers {
  const MockPremiumOffers._();

  static const List<PremiumOffer> all = <PremiumOffer>[
    PremiumOffer(
      id: 'mock_monthly',
      period: PremiumPeriod.monthly,
      priceLabel: r'$4.99',
    ),
    PremiumOffer(
      id: 'mock_yearly',
      period: PremiumPeriod.yearly,
      priceLabel: r'$29.99',
      trialDays: 7,
    ),
    PremiumOffer(
      id: 'mock_lifetime',
      period: PremiumPeriod.lifetime,
      priceLabel: r'$44.99',
    ),
  ];
}
