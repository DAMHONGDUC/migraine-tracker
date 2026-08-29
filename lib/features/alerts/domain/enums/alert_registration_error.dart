/// Why enabling alerts failed — mapped to a user-facing message in the UI.
enum AlertRegistrationError {
  /// No signed-in account. Alerts need premium and premium needs an account (hard rule 7), so there is nothing to register against.
  accountRequired,
  notificationsDenied,
  locationUnavailable,
  pushUnavailable,
  unknown,
}

class AlertRegistrationException implements Exception {
  const AlertRegistrationException(this.error);

  final AlertRegistrationError error;
}
