import { shouldAlert } from "./alerts";
import { AlertUser, groupByGeohash } from "./grouping";
import { DropForecast } from "./pressure";
import { isQuietHour } from "./quietHours";

/** The stale-token error code FCM returns once an app is uninstalled or its token rotates. */
export const STALE_TOKEN_CODE = "messaging/registration-token-not-registered";

/** Side-effecting dependencies of {@link runPressureAlerts}, injected so the orchestration (grouping, dedupe, stale-token cleanup, fail-loud on weather. */
export interface AlertRunDeps {
  now: Date;
  /** The worst 24h pressure drop for a geohash cell, or null when nothing in the window crosses into a drop. */
  fetchCellDrop: (geohash5: string) => Promise<DropForecast | null>;
  /** Sends the push. `silent` means it lands in the user's local night and must arrive without a sound. Throws on failure; `error.code` drives token cleanup. */
  sendPush: (
    user: AlertUser,
    drop: DropForecast,
    options: { silent: boolean },
  ) => Promise<void>;
  /** Persists dedupe state (lastAlertAt/lastAlertEventId/lastAlertDropHpa) after a push. */
  recordAlert: (uid: string, drop: DropForecast, now: Date) => Promise<void>;
  /** Removes a stale FCM token so the doc stops costing work. */
  removeToken: (uid: string) => Promise<void>;
  logError?: (message: string, data: Record<string, unknown>) => void;
  logInfo?: (message: string, data: Record<string, unknown>) => void;
}

/**
 * What one cell's forecast said. Kept because a run that sent nothing is the
 * usual run, and without the reading behind it the record cannot say whether
 * that was a flat forecast, a drop under everyone's threshold, or dedupe.
 */
export interface CellDrop {
  currentHpa: number;
  /** Positive = falling; negative is a rising forecast and is worth seeing. */
  dropHpa: number;
  eventId: string;
}

export interface AlertRunResult {
  users: number;
  cells: number;
  failedCells: string[];
  pushesSent: number;
  /** Of {@link pushesSent}, how many went out silently — the number that says whether a quiet night was the run working or the offsets being wrong. */
  silentPushes: number;
  /** Keyed by geohash5. A fetched cell is missing only when its forecast held no usable sample. */
  cellDrops: Record<string, CellDrop>;
}

/** Core of the pressure-alert cron, pure orchestration over injected effects. */
export async function runPressureAlerts(
  users: AlertUser[],
  deps: AlertRunDeps,
): Promise<AlertRunResult> {
  const { now } = deps;
  const cells = groupByGeohash(users);
  const failedCells: string[] = [];
  const cellDrops: Record<string, CellDrop> = {};
  let pushesSent = 0;
  let silentPushes = 0;

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
    cellDrops[cell] = {
      currentHpa: drop.currentHpa,
      dropHpa: drop.dropHpa,
      eventId: drop.eventId,
    };

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
      const silent = isQuietHour(now, user.tzOffsetMinutes);
      try {
        await deps.sendPush(user, drop, { silent });
        await deps.recordAlert(user.uid, drop, now);
        pushesSent++;
        if (silent) silentPushes++;
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

  return {
    users: users.length,
    cells: cells.size,
    failedCells,
    pushesSent,
    silentPushes,
    cellDrops,
  };
}
