import 'dart:io';

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

  // --- Firebase (non-secret identifiers; access control is Firestore rules). ---
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
  /// `main()`'s own check is [missingConfigKeys]; this getter stays as a
  /// cheap yes/no for call sites that don't need the full gap list.
  static bool get hasFirebaseConfig => firebaseProjectId.isNotEmpty;

  /// Human-readable reminder for the fail-loud path in `main()`.
  static const String missingConfigMessage =
      'Firebase config missing. Run with '
      '--dart-define-from-file=env/dev.json (or env/prod.json).';

  // --- RevenueCat (public SDK keys; entitlement is decided server-side). ---
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  /// Entitlement identifier configured in the RevenueCat dashboard — the one
  /// name that decides whether a customer is premium. Defaulted rather than
  /// required: `premium` is RevenueCat's own convention and the overwhelming
  /// majority of projects keep it.
  static const String revenueCatEntitlement = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
    defaultValue: 'premium',
  );

  /// Offering identifier to show on the paywall. Empty means "whatever the
  /// dashboard marks as current", which is what lets prices and packages be
  /// changed without shipping a build.
  static const String revenueCatOffering = String.fromEnvironment(
    'REVENUECAT_OFFERING',
  );

  /// The key for the store this build runs against. Public by design — the
  /// entitlement is decided by RevenueCat's servers, so leaking it grants
  /// nothing.
  static String get revenueCatKey =>
      Platform.isAndroid ? revenueCatAndroidKey : revenueCatIosKey;

  /// True once a RevenueCat key was passed at build time. `main()`'s own
  /// check is [missingConfigKeys]; this getter stays as a cheap yes/no for
  /// call sites that don't need the full gap list.
  static bool get hasPurchasesConfig => revenueCatKey.isNotEmpty;

  /// Reminder for the fail-loud path in the premium wiring. Purchases have
  /// no offline or debug fallback on purpose: a client-side premium flag is
  /// exactly what CLAUDE.md forbids, so a missing key is a build error, not
  /// a silently free app.
  static const String missingPurchasesConfigMessage =
      'RevenueCat config missing. Add REVENUECAT_IOS_KEY / '
      'REVENUECAT_ANDROID_KEY to env/dev.json (or env/prod.json) and run with '
      '--dart-define-from-file.';

  // --- Support ---

  /// Inbox shown on the Contact support screen and used as the `mailto:`
  /// recipient. Defaulted to a sample address rather than required — swap
  /// SUPPORT_EMAIL in env/*.json for the real inbox when there is one.
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@baroease.app',
  );

  // --- Legal ---

  /// Privacy Policy the paywall links to — App Store 3.1.2 wants it in the
  /// binary, not just the listing. From env because this page is ours and can
  /// move; the two Apple URLs beside it in `LegalUrlConstant` never do, so
  /// only this one would otherwise need a code change and a release to follow
  /// a re-host. Defaulted to the live page, so an unset build is unchanged.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  // --- Boot-time validation ---

  /// Every config value the app cannot run without, keyed by its dart-define
  /// name. Only the platform's own RevenueCat key is required — the other
  /// platform's is allowed to stay empty (Android isn't polished yet).
  /// `revenueCatOffering`, `supportEmail` and `privacyPolicyUrl` are
  /// deliberately excluded: all are meant to be empty/defaulted, not missing
  /// config.
  static Map<String, String> get _requiredConfig => {
    'FIREBASE_ANDROID_API_KEY': firebaseAndroidApiKey,
    'FIREBASE_ANDROID_APP_ID': firebaseAndroidAppId,
    'FIREBASE_IOS_API_KEY': firebaseIosApiKey,
    'FIREBASE_IOS_APP_ID': firebaseIosAppId,
    'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
    'FIREBASE_PROJECT_ID': firebaseProjectId,
    'FIREBASE_STORAGE_BUCKET': firebaseStorageBucket,
    'FIREBASE_IOS_BUNDLE_ID': firebaseIosBundleId,
    if (Platform.isAndroid)
      'REVENUECAT_ANDROID_KEY': revenueCatAndroidKey
    else
      'REVENUECAT_IOS_KEY': revenueCatIosKey,
  };

  /// Names of every required key still empty. Walked by the single fail-loud
  /// assert in `main()` so a missing `--dart-define-from-file` reports every
  /// gap at once instead of a separate assert per config group.
  static List<String> get missingConfigKeys => [
    for (final MapEntry<String, String> entry in _requiredConfig.entries)
      if (entry.value.isEmpty) entry.key,
  ];
}
