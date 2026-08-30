/**
 * The owner-managed allow-list in Firestore — one document per address, id =
 * the address lower-cased. Replaces the PREMIUM_EMAIL build flag, which took a
 * redeploy of both the app and the functions to change.
 *
 * The document id IS the address so that a client can be given a read of its
 * own row and no way to list the rest; see the `app_access` block in
 * `firestore.rules`.
 */
export const ACCESS_COLLECTION = "app_access";

/** Premium in the app whatever RevenueCat says, and a target of the pressure-alert cron. */
export const PREMIUM_FIELD = "premium";

/** Shows the Dev group in Settings. Read by the app only — no function branches on it. */
export const DEV_SETTINGS_FIELD = "devSettings";

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
