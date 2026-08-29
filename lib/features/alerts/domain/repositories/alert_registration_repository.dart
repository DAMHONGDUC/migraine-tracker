/// Registers this device for pressure-drop pushes.
abstract interface class AlertRegistrationRepository {
  /// Ensures an (anonymous) account, asks for notification permission, and writes the registration doc. Throws [AlertRegistrationException].
  Future<void> register({required double thresholdHpa});

  /// Pushes only the new threshold (no-op when never registered).
  Future<void> updateThreshold(double thresholdHpa);

  /// Removes the FCM token so the cron stops targeting this device.
  Future<void> unregister();

  /// Forgets everything this device ever told the backend — the token, the geohash, the threshold and the timezone.
  Future<void> forgetRegistration();

  /// Registers this device's push token, then asks the backend to push to it.
  Future<void> sendTestPush();
}
