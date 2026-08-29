/** Collections holding a user's synced records, keyed by `userId`. */
export const SYNCED_COLLECTIONS = [
  "attacks",
  "medications",
  "medication_reminders",
] as const;

/** Side-effecting parts of {@link tearDownAccount}, injected so the order and the failure handling can be tested without Firestore or Auth. */
export interface AccountTeardownDeps {
  /** Deletes every document in [collection] whose `userId` is [uid]. */
  deleteRecords: (uid: string, collection: string) => Promise<number>;
  deleteUserDoc: (uid: string) => Promise<void>;
  deleteSyncKey: (uid: string) => Promise<void>;
  deleteAuthUser: (uid: string) => Promise<void>;
  logInfo: (message: string, data: Record<string, unknown>) => void;
}

export interface AccountTeardownResult {
  deleted: number;
}

/** Removes everything the backend holds about a user, then the account itself. */
export async function tearDownAccount(
  uid: string,
  deps: AccountTeardownDeps,
): Promise<AccountTeardownResult> {
  if (uid.length === 0) throw new Error("uid required");

  let deleted = 0;
  for (const collection of SYNCED_COLLECTIONS) {
    deleted += await deps.deleteRecords(uid, collection);
  }

  await deps.deleteUserDoc(uid);
  // Without this the key outlives the account that owned it, and no client can ever reach it to clean up.
  await deps.deleteSyncKey(uid);
  await deps.deleteAuthUser(uid);

  deps.logInfo("account torn down", { uid, deleted });
  return { deleted };
}
