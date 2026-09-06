/// Every name in the `app_config/app` document, in one place.
///
/// It lives in `domain/` rather than beside a repository because **two features
/// read this document**: `app_config` takes the switches and the address lists,
/// `app_update` takes [forceUpdateField]. Cross-feature imports may only reach
/// `domain/`, and a Firestore field name that two features spell separately is
/// a field one of them will one day spell wrong — silently, since an unknown
/// key reads as absent rather than as an error.
abstract final class AppConfigSchema {
  static const String collectionPath = 'app_config';

  /// The only document in the collection. A fixed id, so every reader asks for the same one and no `orderBy` decides which config is current.
  static const String documentId = 'app';

  /// The app-wide premium kill switch.
  static const String premiumEnabledField = 'premium_enabled';

  /// The force-update record: `{ios: {...}, android: {...}}`, read by `AppUpdateMapper`.
  static const String forceUpdateField = 'force_update';

  /// Premium in the app whatever RevenueCat says, and targets of the pressure-alert cron.
  static const String premiumEmailsField = 'premium_emails';

  /// Addresses that see the Dev group in Settings on a prod build. snake_case, like every Firestore field — see `docs/rules/DATA_AND_SYNC.md`.
  static const String devModeEmailsField = 'dev_mode_emails';

  /// Addresses locked out of the app.
  static const String blockedEmailsField = 'blocked_emails';
}
