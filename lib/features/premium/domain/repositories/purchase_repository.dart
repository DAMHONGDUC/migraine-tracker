import '../entities/premium_offer.dart';

/// Buying premium.
abstract interface class PurchaseRepository {
  /// Packages to show, in display order. Empty when the store has no offering configured yet — the paywall says so rather than showing a dead button.
  Future<List<PremiumOffer>> offers();

  /// Runs the store's payment sheet.
  Future<bool> purchase(PremiumOffer offer);

  /// Re-applies a purchase made on another device or before a reinstall. Returns whether the entitlement came back.
  Future<bool> restore();

  /// The store's own page for this customer's subscription, or null when the store has nothing to manage — no purchase on the account, or premium granted by the build rather than bought. Cancelling and changing plan happen only there.
  Future<String?> managementUrl();

  /// Binds purchases to the signed-in account, so an entitlement follows the user rather than the install. Called on sign-in.
  Future<void> identify(String uid);

  /// Unbinds on sign-out, so the next account on this device does not inherit the previous one's entitlement.
  Future<void> forget();
}
