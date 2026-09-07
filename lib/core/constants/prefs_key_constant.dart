/// Every `SecureStore` key the app writes, in one place. The one `shared_preferences` key is [lastEnv], which lives there precisely because iOS deletes it with the app.
final class PrefsKeyConstant {
  /// The flavour the last launch ran as — `dev`, `prod` — and the only key
  /// this app keeps in `shared_preferences`.
  ///
  /// **There on purpose, and it is two answers in one.** iOS deletes that
  /// store with the app, so a value that differs from this build means the
  /// environment changed and an absent one means this install has not run
  /// before. See `SdFreshInstall`, which owns both readings.
  static const String lastEnv = 'last_env';

  /// Onboarding has been completed — the router's redirect reads this.
  static const String onboardingCompleted = 'onboarding_completed';

  /// The pressure-drop threshold picked during onboarding, in hPa.
  static const String alertThreshold = 'alert_threshold';

  static const String alertsEnabled = 'alerts_enabled';

  /// Whether the app has already switched pressure alerts on by itself, once,
  /// for an account that qualified. Present means "asked" — including an
  /// attempt that failed — so the OS notification prompt is never raised twice
  /// by a decision the user did not make. See `AlertsController.autoEnableOnce`.
  static const String alertsAutoEnabled = 'alerts_auto_enabled';

  /// The single flag both health sources shared before they were split.
  static const String healthConnected = 'health_connected';

  static const String healthSleep = 'health_sleep_connected';
  static const String healthSteps = 'health_steps_connected';

  /// The Live Activity currently on the Lock Screen, by attack id. Stored rather than held in memory because the card outlives the process.
  static const String liveActivityId = 'live_activity_id';

  /// The cycle switch. Its own key, and deliberately NOT covered by the legacy `healthConnected` fallback: nobody consented to a reproductive-health read under a switch that predates it.
  static const String healthCycle = 'health_cycle_connected';

  /// A `DevLocation` name, pinning weather reads to a fixed city instead of the device position. Absent = off. Dev builds only — the controller
  /// ignores it outright in a prod flavour.
  static const String devFakeLocation = 'dev_fake_location';

  /// Whether the home-screen widget is fed. Absent means on: a widget the user placed themselves and then found empty reads as broken.
  static const String homeWidgetEnabled = 'home_widget_enabled';

  /// How many times the store review prompt has been asked for, and when the last one was (ISO-8601, UTC). Absent = never asked.
  static const String reviewPromptCount = 'review_prompt_count';
  static const String reviewPromptLastAskedAt = 'review_prompt_last_asked_at';

  /// Prefixes, not keys: the uid and the collection are appended (see `PrefsSyncCursorStore`).
  static const String syncCursorPrefix = 'sync_last_pulled_at_';
  static const String syncLastSyncedAtPrefix = 'sync_last_synced_at_';
}
