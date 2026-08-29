/** AES-256: the key the client encrypts attack payloads with. */
export const SYNC_KEY_BYTES = 32;

/** Base64 length of {@link SYNC_KEY_BYTES} raw bytes. */
const SYNC_KEY_BASE64_LENGTH = 44;

/** Sign-in providers Firebase reports for a real account. */
export const ANONYMOUS_PROVIDER = "anonymous";

/** Side-effecting dependencies of {@link resolveSyncKey}, injected so the read-or-create policy can be unit-tested without Firestore or a real RNG. */
export interface SyncKeyDeps {
  load: (uid: string) => Promise<string | null>;
  save: (uid: string, key: string, now: Date) => Promise<void>;
  generateKey: () => string;
  now: Date;
}

/** The user's existing key, or a freshly minted one on first use. */
export async function resolveSyncKey(
  uid: string,
  deps: SyncKeyDeps,
): Promise<string> {
  if (uid.length === 0) throw new Error("uid required");

  const existing = await deps.load(uid);
  if (existing !== null) {
    if (!isWellFormedKey(existing)) {
      throw new Error(`stored sync key for ${uid} is malformed`);
    }
    return existing;
  }

  const key = deps.generateKey();
  if (!isWellFormedKey(key)) {
    throw new Error("generated sync key is malformed");
  }
  await deps.save(uid, key, deps.now);
  return key;
}

export function isWellFormedKey(key: unknown): key is string {
  if (typeof key !== "string" || key.length !== SYNC_KEY_BASE64_LENGTH) {
    return false;
  }
  return Buffer.from(key, "base64").length === SYNC_KEY_BYTES;
}
