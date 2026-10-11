/**
 * The owner-managed `app_config/current` document in Firestore — one document
 * holding every switch: the force-update record and the three address lists.
 * It replaced the PREMIUM_EMAIL build flag, which took a redeploy of both the
 * app and the functions to change.
 *
 * See the `app_config` block in `firestore.rules` for why it is one
 * world-readable document rather than a row per address.
 */
export const APP_CONFIG_COLLECTION = "app_config";

/** The only document in the collection. */
export const APP_CONFIG_DOCUMENT = "current";

/** Premium in the app whatever RevenueCat says, and targets of the pressure-alert cron. */
export const PREMIUM_EMAILS_FIELD = "premium_emails";

/** `true`: pressure alerts go to every registered account, not only premium. The app reads it too, to show the controls. */
export const FREE_PRESSURE_ALERTS_FIELD = "free_pressure_alerts";

/** Shows the Dev group in Settings. Read by the app only — no function branches on it. */
export const DEV_MODE_EMAILS_FIELD = "dev_mode_emails";

/** Locked out of the app. Read by the app only. */
export const BLOCKED_EMAILS_FIELD = "blocked_emails";

/**
 * The addresses the list grants premium: trimmed, lower-cased, de-duplicated,
 * blanks and non-strings dropped.
 *
 * Normalised here rather than trusted, because the list is typed by hand in the
 * console and " Review@BaroEase.app " is what a copy-paste actually produces.
 * Firebase Auth stores addresses lower-cased, so this is the spelling
 * `getUserByEmail` will match.
 *
 * Anything that is not an array is an empty list — a malformed field must send
 * no pushes rather than throw the whole run.
 */
export function premiumEmailsFrom(value: unknown): string[] {
  if (!Array.isArray(value)) return [];

  const emails = new Set<string>();

  for (const entry of value) {
    if (typeof entry !== "string") continue;

    const email = entry.trim().toLowerCase();
    if (email.length > 0) emails.add(email);
  }

  return [...emails];
}

/**
 * Whether the owner has opened pressure alerts to every account.
 *
 * Explicit `true` only — `"true"`, `1` and absent are all off. Opening it spends
 * a WeatherKit call per cell on every account, so a typo must not be able to.
 */
export function freePressureAlertsFrom(value: unknown): boolean {
  return value === true;
}
