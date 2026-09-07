/// Every name in the `app_config/current` document, in one place.
///
/// **One reader now**: `FirestoreAppConfigRepository` takes every field below,
/// [forceUpdateField] included, and hands back one `AppConfig`. It was two
/// features and then two repositories, each spelling this path for itself —
/// and a Firestore name spelled in two places is a name one of them will one
/// day spell wrong, silently, since an unknown key reads as absent rather than
/// as an error. It stays in `domain/` because the mapper and the entity both
/// reach it from layers that may not import `data/`.
abstract final class AppConfigSchema {
  static const String collectionPath = 'app_config';

  /// The only document in the collection. A fixed id, so every reader asks for the same one and no `orderBy` decides which config is current.
  static const String documentId = 'current';

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
