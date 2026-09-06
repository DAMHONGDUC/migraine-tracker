/// Every name in the `app_config` collection, in one place — the collection, both
/// document kinds, and every field either of them carries.
///
/// It lives in `domain/` rather than beside a repository because **two features
/// read this collection**: `app_config` itself takes the grants and the
/// switches, `app_update` takes [forceUpdateField]. Cross-feature imports may
/// only reach `domain/`, and a Firestore field name that two features spell
/// separately is a field one of them will one day spell wrong — silently, since
/// an unknown key reads as absent rather than as an error.
abstract final class AppConfigSchema {
  static const String collectionPath = 'app_config';

  /// The one document that is not an address. `app` can never collide with a row: rows are keyed on the token address, and no address is the bare word.
  static const String globalDocumentId = 'app';

  // --- Fields on a row, `app_config/{email}` ---

  /// Premium in the app whatever RevenueCat says, and a target of the pressure-alert cron.
  static const String premiumField = 'premium';

  /// Settings shows its Dev group. snake_case, like every Firestore field — see `docs/rules/DATA_AND_SYNC.md`.
  static const String devSettingsField = 'dev_settings';

  /// The address is locked out: the app signs it out and says so. Only ever a row, never a global switch — blocking everybody at once is what [premiumEnabledField] and force update are for.
  static const String blockedField = 'blocked';

  // --- Fields on the global document, `app_config/app` ---

  /// The app-wide premium kill switch.
  static const String premiumEnabledField = 'enable_premium';

  /// The force-update record: `{ios: {...}, android: {...}}`, read by `AppUpdateMapper`.
  static const String forceUpdateField = 'force_update';

  /// The one spelling both sides agree on: the app lower-cases before the read, the owner lower-cases when creating the row, and Firebase Auth already stores addresses lower-cased.
  static String rowId(String email) => email.trim().toLowerCase();
}
