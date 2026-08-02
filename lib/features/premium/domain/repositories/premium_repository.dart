/// Whether the user has an active premium entitlement.
///
/// Backed by RevenueCat entitlements — never a flag the client can set
/// (CLAUDE.md). There is deliberately no local/debug implementation: one
/// existed while the SDK was being wired, and a repository whose premium
/// state a `setPremium` call could flip is exactly the thing that must not
/// ship. Tests override the provider with a fake instead.
abstract interface class PremiumRepository {
  /// The entitlement right now — lets gates decide on the very first frame
  /// instead of flashing a locked state while a stream resolves.
  bool get isPremium;

  Stream<bool> watchIsPremium();
}
