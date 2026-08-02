/// Why a purchase or restore did not end in an entitlement.
///
/// [cancelled] is not a failure — the user closed Apple's sheet. It exists so
/// the UI can stay silent for it instead of showing an error for a deliberate
/// act (same rule as `AuthError.cancelled`).
enum PurchaseError {
  cancelled,

  /// Store unreachable. Retryable, and worth saying so.
  network,

  /// Already entitled — a restore usually fixes this, so the UI says that.
  alreadyOwned,

  /// Deferred: the store accepted it but is waiting (Ask to Buy, SCA). The
  /// entitlement may arrive later, so nothing should be reported as failed.
  pending,

  /// Purchases are disabled on this device (parental controls, MDM).
  notAllowed,

  /// The store had nothing to restore for this account.
  nothingToRestore,

  /// RevenueCat is not configured in this build — a wiring error, never
  /// something the user can act on.
  notConfigured,

  unknown,
}

class PurchaseException implements Exception {
  const PurchaseException(this.error, [this.message]);

  final PurchaseError error;

  /// The store's own text, kept for logs and crash reports — never shown
  /// raw to the user, who gets a localized string instead.
  final String? message;

  @override
  String toString() => 'PurchaseException($error${message == null ? '' : ': $message'})';
}
