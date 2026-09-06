/**
 * The owner-managed `app_config/app` document in Firestore — one document
 * holding every switch: the premium kill switch, the force-update record, and
 * the three address lists. It replaced the PREMIUM_EMAIL build flag, which took
 * a redeploy of both the app and the functions to change.
 *
 * See the `app_config` block in `firestore.rules` for why it is one
 * world-readable document rather than a row per address.
 */
export const APP_CONFIG_COLLECTION = "app_config";

/** The only document in the collection. */
export const APP_CONFIG_DOCUMENT = "app";

/** The app-wide premium kill switch. */
export const PREMIUM_ENABLED_FIELD = "premium_enabled";

/** Premium in the app whatever RevenueCat says, and targets of the pressure-alert cron. */
export const PREMIUM_EMAILS_FIELD = "premium_emails";

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
 * Whether premium exists at all right now.
 *
 * Defaults to ON — an absent document, an absent field, and anything that is
 * not exactly `false` all mean "the owner never threw the switch". Same
 * direction as the app (`AppConfig.empty`), and for the same reason: a read
 * that goes wrong must not silently stop alerting people who pay for it. Only
 * a real `false` turns it off, so `"false"` typed into the console as a string
 * does nothing.
 */
export function premiumEnabledFrom(config: unknown): boolean {
  if (config === undefined || config === null) return true;
  if (typeof config !== "object") return true;

  return (config as Record<string, unknown>)[PREMIUM_ENABLED_FIELD] !== false;
}
