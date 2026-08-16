/// Every `shared_preferences` key the app writes, in one place.
///
/// One class rather than a key per controller, because the risk these carry
/// is collision: two features picking the same string silently overwrite each
/// other, and nothing in the type system notices. Listed together, a clash is
/// visible.
final class PrefsKeyConstant {
  /// Onboarding has been completed — the router's redirect reads this.
  static const String onboardingCompleted = 'onboarding_completed';

  /// The pressure-drop threshold picked during onboarding, in hPa.
  static const String alertThreshold = 'alert_threshold';

  static const String alertsEnabled = 'alerts_enabled';

  /// The single flag both health sources shared before they were split. Still
  /// read as a fallback so a user who connected under it is not silently
  /// disconnected — see `HealthController`.
  static const String healthConnected = 'health_connected';

  static const String healthSleep = 'health_sleep_connected';
  static const String healthSteps = 'health_steps_connected';

  /// A `DevLocation` name, pinning weather reads to a fixed city instead of
  /// the device position. Absent = off. Dev builds only — the controller
  /// ignores it outright in a prod flavour.
  static const String devFakeLocation = 'dev_fake_location';

  /// Seeds the dev-only fake HealthKit. Absent = off, so the real plugin is
  /// used; present = the dev seed has run and the number generates a stable
  /// history. Dev builds only — nothing in prod ever writes it.
  static const String devHealthSeed = 'dev_health_seed';

  /// Whether the home-screen widget is fed. Absent means on: a widget the
  /// user placed themselves and then found empty reads as broken.
  static const String homeWidgetEnabled = 'home_widget_enabled';

  /// How many times the store review prompt has been asked for, and when the
  /// last one was (ISO-8601, UTC). Absent = never asked.
  static const String reviewPromptCount = 'review_prompt_count';
  static const String reviewPromptLastAskedAt = 'review_prompt_last_asked_at';

  /// Prefixes, not keys: the uid and the collection are appended (see
  /// `PrefsSyncCursorStore`).
  static const String syncCursorPrefix = 'sync_last_pulled_at_';
  static const String syncLastSyncedAtPrefix = 'sync_last_synced_at_';
}
