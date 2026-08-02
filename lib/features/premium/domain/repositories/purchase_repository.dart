import '../entities/premium_offer.dart';

/// Buying premium. Separate from `PremiumRepository` on purpose: that one
/// answers "is this customer entitled right now" and is read by every gate in
/// the app, this one is only touched by the paywall. Splitting them keeps the
/// gate path free of anything that can prompt a payment sheet.
abstract interface class PurchaseRepository {
  /// Packages to show, in display order. Empty when the store has no offering
  /// configured yet — the paywall says so rather than showing a dead button.
  Future<List<PremiumOffer>> offers();

  /// Runs the store's payment sheet. Returns true once the entitlement is
  /// active; throws [PurchaseException] otherwise, including for a user
  /// cancellation, which the caller is expected to swallow.
  Future<bool> purchase(PremiumOffer offer);

  /// Re-applies a purchase made on another device or before a reinstall.
  /// Returns whether the entitlement came back.
  Future<bool> restore();

  /// Binds purchases to the signed-in account, so an entitlement follows the
  /// user rather than the install. Called on sign-in.
  Future<void> identify(String uid);

  /// Unbinds on sign-out, so the next account on this device does not inherit
  /// the previous one's entitlement.
  Future<void> forget();
}
