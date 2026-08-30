import { AlertRunResult } from "./alertRun";

/**
 * What one pressureAlertJob run is written down as. The job is a cron: nobody
 * watches it happen, and by the time a user reports "I never got an alert" the
 * Cloud Logging retention window may already have closed over the run that
 * should have sent it.
 */
export const ALERT_RUN_COLLECTION = "pressure_alert_runs";

/** `ok` sent what it meant to, `partial` finished with cells it could not fetch, `failed` threw and did not finish at all. */
export type AlertRunStatus = "ok" | "partial" | "failed";

export interface AlertRunRecord {
  startedAt: Date;
  finishedAt: Date;
  durationMs: number;
  status: AlertRunStatus;
  /** Users the run considered — premium subscribers plus the allow-list, deduped. */
  users: number;
  /** Distinct geohash cells fetched, i.e. how many WeatherKit calls the run spent. */
  cells: number;
  pushesSent: number;
  /** Capped at {@link FAILED_CELL_LIMIT}; `failedCellCount` is always the true total. */
  failedCells: string[];
  failedCellCount: number;
  /** Null on any run that finished, whatever its status. */
  error: string | null;
}

/** A run failing wholesale fails every cell it had, and a document is capped at 1 MiB — so the list is a sample and the count is the fact. */
export const FAILED_CELL_LIMIT = 50;

/** Sortable, unique per run, and readable in the console without opening the document. */
export function alertRunId(startedAt: Date): string {
  return startedAt.toISOString();
}

/** Builds the record. `result` is null when the run threw before producing one. */
export function alertRunRecord(input: {
  startedAt: Date;
  finishedAt: Date;
  result: AlertRunResult | null;
  error?: unknown;
}): AlertRunRecord {
  const { startedAt, finishedAt, result, error } = input;
  const failed = result?.failedCells ?? [];
  const status: AlertRunStatus = error !== undefined
    ? "failed"
    : failed.length > 0
      ? "partial"
      : "ok";

  return {
    startedAt,
    finishedAt,
    durationMs: finishedAt.getTime() - startedAt.getTime(),
    status,
    users: result?.users ?? 0,
    cells: result?.cells ?? 0,
    pushesSent: result?.pushesSent ?? 0,
    failedCells: failed.slice(0, FAILED_CELL_LIMIT),
    failedCellCount: failed.length,
    error: error === undefined ? null : String(error),
  };
}
