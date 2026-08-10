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
  ///
  /// Only the token: turning alerts off should not forget the threshold the
  /// user picked, which they will want again when they turn them back on.
  Future<void> unregister();

  /// Forgets everything this device ever told the backend — the token, the
  /// geohash, the threshold and the timezone.
  ///
  /// For the GDPR wipe, which must leave nothing behind that could still
  /// reach the user or say where they were. Clears fields rather than
  /// deleting the document: `premium` belongs to the RevenueCat webhook and
  /// a paying subscriber must not lose alerts by clearing their history —
  /// and the rules forbid a client touching that key anyway.
  Future<void> forgetRegistration();

  /// Asks the backend to push to this device's own registered token.
  ///
  /// The one thing no test can prove: that the APNs key, the entitlement and
  /// the token line up on real hardware. Throws when the device never
  /// registered, which is itself the answer.
  Future<void> sendTestPush();
}
