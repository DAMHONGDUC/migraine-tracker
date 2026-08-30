import 'dart:io';

/// Single source of truth for compile-time configuration injected via `--dart-define-from-file=env/<flavor>.json`.
///
/// A key owned by one platform ends in `_IOS` or `_ANDROID` and its getter ends in the same word; no suffix means both platforms read it (`docs/setup/ENV_AND_FASTLANE_SPEC.md` A3).
final class AppEnv {
  const AppEnv._();

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static bool get isProd => flavor == 'prod';

  /// `true`/`false` to decide the Dev group by hand; empty — the normal state — lets the flavour decide (see [showDevSettings]).
  static const String _showDevSettings = String.fromEnvironment(
    'SHOW_DEV_SETTINGS',
  );

  /// Whether Settings shows its Dev group. Unset it follows the flavour, which is what every build did before the key existed; set on a prod build it is how a TestFlight tester reaches the fixtures without a dev Firebase project behind them.
  static bool get showDevSettings => _showDevSettings.isEmpty
      ? !isProd
      : _showDevSettings.toLowerCase() == 'true';

  // --- Firebase (non-secret identifiers; access control is Firestore rules). ---
  static const String firebaseApiKeyAndroid = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
  );
  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );
  static const String firebaseApiKeyIos = String.fromEnvironment(
    'FIREBASE_API_KEY_IOS',
  );
  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
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
  static const String firebaseBundleIdIos = String.fromEnvironment(
    'FIREBASE_BUNDLE_ID_IOS',
  );

  /// True once the required Firebase values were passed at build time.
  static bool get hasFirebaseConfig => firebaseProjectId.isNotEmpty;

  /// Human-readable reminder for the fail-loud path in `main()`.
  static const String missingConfigMessage =
      'Firebase config missing. Run with '
      '--dart-define-from-file=env/dev.json (or env/prod.json).';

  // --- RevenueCat (public SDK keys; entitlement is decided server-side). ---
  static const String revenueCatKeyIos = String.fromEnvironment(
    'REVENUECAT_KEY_IOS',
  );
  static const String revenueCatKeyAndroid = String.fromEnvironment(
    'REVENUECAT_KEY_ANDROID',
  );

  /// Entitlement identifier configured in the RevenueCat dashboard — the one name that decides whether a customer is premium.
  static const String revenueCatEntitlement = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
    defaultValue: 'premium',
  );

  /// Offering identifier to show on the paywall.
  static const String revenueCatOffering = String.fromEnvironment(
    'REVENUECAT_OFFERING',
  );

  /// The key for the store this build runs against. Public by design — the entitlement is decided by RevenueCat's servers, so leaking it grants nothing.
  static String get revenueCatKey =>
      Platform.isAndroid ? revenueCatKeyAndroid : revenueCatKeyIos;

  /// True once a RevenueCat key was passed at build time.
  static bool get hasPurchasesConfig => revenueCatKey.isNotEmpty;

  /// Reminder for the fail-loud path in the premium wiring.
  static const String missingPurchasesConfigMessage =
      'RevenueCat config missing. Add REVENUECAT_KEY_IOS / '
      'REVENUECAT_KEY_ANDROID to env/dev.json (or env/prod.json) and run with '
      '--dart-define-from-file.';

  // --- Support ---

  /// Inbox shown on the Contact support screen and used as the `mailto:` recipient.
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@baroease.app',
  );

  /// Account that is premium on any build carrying this key, whatever RevenueCat says.
  static const String premiumEmail = String.fromEnvironment('PREMIUM_EMAIL');

  // --- Legal ---

  /// Privacy Policy the paywall links to — App Store 3.1.2 wants it in the binary, not just the listing.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  // --- Boot-time validation ---

  /// Every config value the app cannot run without, keyed by its dart-define name.
  static Map<String, String> get _requiredConfig => {
    'FIREBASE_API_KEY_ANDROID': firebaseApiKeyAndroid,
    'FIREBASE_APP_ID_ANDROID': firebaseAppIdAndroid,
    'FIREBASE_API_KEY_IOS': firebaseApiKeyIos,
    'FIREBASE_APP_ID_IOS': firebaseAppIdIos,
    'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
    'FIREBASE_PROJECT_ID': firebaseProjectId,
    'FIREBASE_STORAGE_BUCKET': firebaseStorageBucket,
    'FIREBASE_BUNDLE_ID_IOS': firebaseBundleIdIos,
    if (Platform.isAndroid)
      'REVENUECAT_KEY_ANDROID': revenueCatKeyAndroid
    else
      'REVENUECAT_KEY_IOS': revenueCatKeyIos,
  };

  /// Names of every required key still empty.
  static List<String> get missingConfigKeys => [
    for (final MapEntry<String, String> entry in _requiredConfig.entries)
      if (entry.value.isEmpty) entry.key,
  ];
}
