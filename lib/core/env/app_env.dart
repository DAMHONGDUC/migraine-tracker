/// Single source of truth for compile-time configuration injected via
/// `--dart-define-from-file=env/<flavor>.json`.
///
/// This is the ONLY place `String.fromEnvironment` is allowed — everything
/// else reads typed getters here, so a renamed key or a missing value is a
/// one-line fix and the set of expected keys is self-documenting.
final class AppEnv {
  const AppEnv._();

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static bool get isProd => flavor == 'prod';

  // --- Firebase (non-secret client identifiers; access control is in
  // Firestore Security Rules, not these values). ---
  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );

  /// True once the required Firebase values were passed at build time.
  /// Lets `main()` fail loud with a clear message instead of a cryptic
  /// Firebase init error when the `--dart-define-from-file` flag is missing.
  static bool get hasFirebaseConfig => firebaseProjectId.isNotEmpty;

  /// Human-readable reminder for the fail-loud path in `main()`.
  static const String missingConfigMessage =
      'Firebase config missing. Run with '
      '--dart-define-from-file=env/dev.json (or env/prod.json).';
}
