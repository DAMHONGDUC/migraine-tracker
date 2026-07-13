/// Why enabling alerts failed — mapped to a user-facing message in the UI.
enum AlertRegistrationError {
  notificationsDenied,
  locationUnavailable,
  pushUnavailable,
  unknown,
}

class AlertRegistrationException implements Exception {
  const AlertRegistrationException(this.error);

  final AlertRegistrationError error;
}
