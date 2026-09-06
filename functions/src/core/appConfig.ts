/**
 * The owner-managed `app_config` collection in Firestore: one document per
 * address (id = the address lower-cased) plus [FLAGS_DOCUMENT_ID], the single
 * document of switches that apply to every install. Replaces the PREMIUM_EMAIL
 * build flag, which took a redeploy of both the app and the functions to change.
 *
 * The document id IS the address so that a client can be given a read of its
 * own row and no way to list the rest; see the `app_config` block in
 * `firestore.rules`.
 */
export const APP_CONFIG_COLLECTION = "app_config";

/**
 * The one document that is not an address. `app` can never collide with a row:
 * rows are keyed on the token address, and no address is the bare word.
 */
export const FLAGS_DOCUMENT_ID = "app";

/** Premium in the app whatever RevenueCat says, and a target of the pressure-alert cron. */
export const PREMIUM_FIELD = "premium";

/** Shows the Dev group in Settings. Read by the app only — no function branches on it. */
export const DEV_SETTINGS_FIELD = "dev_settings";

/** The app-wide premium kill switch, on [FLAGS_DOCUMENT_ID]. */
export const PREMIUM_ENABLED_FIELD = "enable_premium";

/** One row as it comes back from Firestore. */
export interface AccessRow {
  id: string;
  premium: unknown;
}

/**
 * The addresses the list grants premium: trimmed, lower-cased, de-duplicated,
 * blanks dropped.
 *
 * Normalised here rather than trusted, because the id is typed by hand in the
 * console and " Review@BaroEase.app " is what a copy-paste actually produces.
 * Firebase Auth stores addresses lower-cased, so this is the spelling
 * `getUserByEmail` will match.
 */
export function premiumEmailsFrom(rows: AccessRow[]): string[] {
  const emails = new Set<string>();

  for (const row of rows) {
    if (row.premium !== true) continue;

    const email = row.id.trim().toLowerCase();
    if (email.length > 0) emails.add(email);
  }

  return [...emails];
}

/**
 * Whether premium exists at all right now, read off the flags document.
 *
 * Defaults to ON — an absent document, an absent field, and anything that is
 * not exactly `false` all mean "the owner never threw the switch". Same
 * direction as the app (`AppConfigFlags`), and for the same reason: a read
 * that goes wrong must not silently stop alerting people who pay for them.
 * Only a real `false` turns it off, so `"false"` typed into the console as a
 * string does nothing.
 */
export function premiumEnabledFrom(flags: unknown): boolean {
  if (flags === undefined || flags === null) return true;
  if (typeof flags !== "object") return true;

  return (flags as Record<string, unknown>)[PREMIUM_ENABLED_FIELD] !== false;
}
