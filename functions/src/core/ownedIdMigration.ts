/**
 * Moves synced documents from a bare record id to `<userId>_<recordId>` — the
 * shape the app writes since 2026-09-24 (`SdId.owned`).
 *
 * A bare id was shared by every user: a daily log's id is the day, so the
 * first account to sync a day owned `daily_logs/<day>` and every other
 * account was refused for good. The legacy document is its owner's real data,
 * so it is moved, never just deleted.
 */

/** The record's own id, beside the owner-scoped document id. Must match `EncryptedRecordMapper.recordId` in the app. */
export const RECORD_ID_FIELD = "record_id";

/** The document id a record of [userId] lives under. Must match `SdId.owned`. */
export function ownedId(userId: string, recordId: string): string {
  return `${userId}_${recordId}`;
}

/** Anything with a millisecond clock — a Firestore `Timestamp`, or a stand-in in a test. */
export interface HasMillis {
  toMillis(): number;
}

export interface MigrationDoc {
  userId?: unknown;
  updatedAt?: unknown;
  [field: string]: unknown;
}

export type MigrationStep =
  /** Write the legacy document under its owned id, then delete it. */
  | { kind: "move"; to: string; data: MigrationDoc }
  /** The owned copy is already as new or newer — only the legacy one goes. */
  | { kind: "dropLegacy" }
  /** Already an owned id, or not a record at all; left alone. */
  | { kind: "skip"; reason: "alreadyOwned" | "noOwner" };

function millis(value: unknown): number {
  return typeof (value as HasMillis | undefined)?.toMillis === "function"
    ? (value as HasMillis).toMillis()
    : 0;
}

/**
 * What to do with one document.
 *
 * [target] is the document already at the owned id, if any. When both exist
 * the newer `updatedAt` wins, which is the same rule the app's pull applies —
 * an old build can still have updated the legacy copy after a new build wrote
 * the owned one.
 */
export function planMigration(
  id: string,
  data: MigrationDoc,
  target: MigrationDoc | null,
): MigrationStep {
  const userId = data.userId;

  if (typeof userId !== "string" || userId.length === 0) {
    return { kind: "skip", reason: "noOwner" };
  }
  if (id.startsWith(`${userId}_`)) return { kind: "skip", reason: "alreadyOwned" };
  if (target !== null && millis(target.updatedAt) >= millis(data.updatedAt)) {
    return { kind: "dropLegacy" };
  }
  return {
    kind: "move",
    to: ownedId(userId, id),
    data: { ...data, [RECORD_ID_FIELD]: id },
  };
}
