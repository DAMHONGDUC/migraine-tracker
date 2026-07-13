/// Registers this device for pressure-drop pushes. Hard rule 1: the doc
/// holds ONLY geohash5, fcmToken, alertThreshold, tz — never health data,
/// and never the premium flag (that is the RevenueCat webhook's job).
abstract interface class AlertRegistrationRepository {
  /// Ensures an (anonymous) account, asks for notification permission,
  /// and writes the registration doc. Throws [AlertRegistrationException].
  Future<void> register({required double thresholdHpa});

  /// Pushes only the new threshold (no-op when never registered).
  Future<void> updateThreshold(double thresholdHpa);

  /// Removes the FCM token so the cron stops targeting this device.
  Future<void> unregister();
}
