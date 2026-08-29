/// Whether the user has an active premium entitlement.
abstract interface class PremiumRepository {
  /// The entitlement right now — lets gates decide on the very first frame instead of flashing a locked state while a stream resolves.
  bool get isPremium;

  Stream<bool> watchIsPremium();
}
