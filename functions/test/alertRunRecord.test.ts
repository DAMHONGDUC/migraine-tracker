import { describe, expect, it } from "vitest";

import { AlertRunResult } from "../src/core/alertRun";
import {
  alertRunId,
  alertRunRecord,
  FAILED_CELL_LIMIT,
} from "../src/core/alertRunRecord";

const startedAt = new Date("2026-08-30T12:00:00.000Z");
const finishedAt = new Date("2026-08-30T12:00:04.500Z");

function result(overrides: Partial<AlertRunResult> = {}): AlertRunResult {
  return { users: 3, cells: 2, failedCells: [], pushesSent: 1, ...overrides };
}

describe("alertRunId", () => {
  it("is the start instant, so the console sorts runs by id alone", () => {
    expect(alertRunId(startedAt)).toBe("2026-08-30T12:00:00.000Z");
  });
});

describe("alertRunRecord", () => {
  it("records a clean run as ok, with its duration", () => {
    const record = alertRunRecord({ startedAt, finishedAt, result: result() });

    expect(record.status).toBe("ok");
    expect(record.durationMs).toBe(4500);
    expect(record.users).toBe(3);
    expect(record.cells).toBe(2);
    expect(record.pushesSent).toBe(1);
    expect(record.failedCells).toEqual([]);
    expect(record.failedCellCount).toBe(0);
    expect(record.error).toBeNull();
  });

  it("records a run that finished with failed cells as partial", () => {
    const record = alertRunRecord({
      startedAt,
      finishedAt,
      result: result({ failedCells: ["u4pru"] }),
    });

    expect(record.status).toBe("partial");
    expect(record.failedCells).toEqual(["u4pru"]);
    expect(record.failedCellCount).toBe(1);
    expect(record.error).toBeNull();
  });

  it("records a run that threw as failed, with zeroes and the message", () => {
    const record = alertRunRecord({
      startedAt,
      finishedAt,
      result: null,
      error: new Error("weatherkit 401"),
    });

    expect(record.status).toBe("failed");
    expect(record.users).toBe(0);
    expect(record.cells).toBe(0);
    expect(record.pushesSent).toBe(0);
    expect(record.error).toContain("weatherkit 401");
  });

  it("caps the cell list but never the count — the document has a size limit and the count is the fact", () => {
    const failedCells = Array.from({ length: 120 }, (_, i) => `cell${i}`);
    const record = alertRunRecord({
      startedAt,
      finishedAt,
      result: result({ failedCells }),
    });

    expect(record.failedCells).toHaveLength(FAILED_CELL_LIMIT);
    expect(record.failedCellCount).toBe(120);
  });
});
