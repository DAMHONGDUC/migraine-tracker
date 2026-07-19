/// Whether the user has an active premium entitlement.
///
/// The real implementation reads RevenueCat entitlements — never a flag the
/// client can set (CLAUDE.md). [DebugPremiumRepository] is a stand-in until
/// the RevenueCat SDK is wired; swapping it must not touch any caller.
abstract interface class PremiumRepository {
  /// The entitlement right now — lets gates decide on the very first frame
  /// instead of flashing a locked state while a stream resolves.
  bool get isPremium;

  Stream<bool> watchIsPremium();
}
