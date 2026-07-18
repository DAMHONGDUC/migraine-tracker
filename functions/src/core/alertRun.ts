import { shouldAlert } from "./alerts";
import { AlertUser, groupByGeohash } from "./grouping";
import { DropForecast } from "./pressure";

/**
 * The stale-token error code FCM returns once an app is uninstalled or its
 * token rotates. We drop such tokens so the orphan doc stops costing pushes
 * and weather calls.
 */
export const STALE_TOKEN_CODE = "messaging/registration-token-not-registered";

/**
 * Side-effecting dependencies of {@link runPressureAlerts}, injected so the
 * orchestration (grouping, dedupe, stale-token cleanup, fail-loud on weather
 * errors) can be unit-tested without Firestore, FCM, or the network.
 */
export interface AlertRunDeps {
  now: Date;
  /**
   * The worst 24h pressure drop for a geohash cell, or null when nothing in
   * the window crosses into a drop. Hard rule 9: called ONCE per cell.
   * Throws on weather-API failure — the caller collects and re-throws.
   */
  fetchCellDrop: (geohash5: string) => Promise<DropForecast | null>;
  /** Sends the push. Throws on failure; `error.code` drives token cleanup. */
  sendPush: (user: AlertUser, drop: DropForecast) => Promise<void>;
  /** Persists dedupe state (lastAlertAt/lastAlertEventId) after a push. */
  recordAlert: (uid: string, eventId: string, now: Date) => Promise<void>;
  /** Removes a stale FCM token so the doc stops costing work. */
  removeToken: (uid: string) => Promise<void>;
  logError?: (message: string, data: Record<string, unknown>) => void;
  logInfo?: (message: string, data: Record<string, unknown>) => void;
}

export interface AlertRunResult {
  users: number;
  cells: number;
  failedCells: string[];
  pushesSent: number;
}

/**
 * Core of the pressure-alert cron, pure orchestration over injected effects.
 * Groups users by geohash (one forecast per cell), applies the per-user
 * dedupe policy, pushes, and cleans up stale tokens. A cell whose forecast
 * fetch throws is recorded in {@link AlertRunResult.failedCells} and skipped
 * — the caller decides whether to fail the run, so one bad cell never
 * silently swallows the rest of a cohort.
 */
export async function runPressureAlerts(
  users: AlertUser[],
  deps: AlertRunDeps,
): Promise<AlertRunResult> {
  const { now } = deps;
  const cells = groupByGeohash(users);
  const failedCells: string[] = [];
  let pushesSent = 0;

  for (const [cell, cellUsers] of cells) {
    let drop: DropForecast | null;
    try {
      drop = await deps.fetchCellDrop(cell);
    } catch (error) {
      deps.logError?.("cell forecast failed", {
        cell,
        users: cellUsers.length,
        error: String(error),
      });
      failedCells.push(cell);
      continue;
    }
    if (drop === null) continue;

    for (const user of cellUsers) {
      if (
        !shouldAlert({
          dropHpa: drop.dropHpa,
          thresholdHpa: user.thresholdHpa,
          eventId: drop.eventId,
          history: user.history,
          now,
        })
      ) {
        continue;
      }
      try {
        await deps.sendPush(user, drop);
        await deps.recordAlert(user.uid, drop.eventId, now);
        pushesSent++;
      } catch (error) {
        const code = (error as { code?: string }).code;
        if (code === STALE_TOKEN_CODE) {
          await deps.removeToken(user.uid);
          deps.logInfo?.("stale token removed", { uid: user.uid });
        } else {
          deps.logError?.("push failed", {
            uid: user.uid,
            error: String(error),
          });
        }
      }
    }
  }

  return { users: users.length, cells: cells.size, failedCells, pushesSent };
}
