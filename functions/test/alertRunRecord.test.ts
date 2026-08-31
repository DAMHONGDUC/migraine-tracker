import { describe, expect, it } from "vitest";

import { AlertRunResult } from "../src/core/alertRun";
import {
  alertRunDocument,
  alertRunId,
  alertRunRecord,
  CELL_DROP_LIMIT,
  FAILED_CELL_LIMIT,
} from "../src/core/alertRunRecord";

const startedAt = new Date("2026-08-30T12:00:00.000Z");
const finishedAt = new Date("2026-08-30T12:00:04.500Z");

function result(overrides: Partial<AlertRunResult> = {}): AlertRunResult {
  return {
    users: 3,
    cells: 2,
    failedCells: [],
    pushesSent: 1,
    silentPushes: 0,
    cellDrops: {
      u1234: { currentHpa: 1015, dropHpa: 7, eventId: "2026-08-31T06" },
      gcpvj: { currentHpa: 1008, dropHpa: 1.5, eventId: "2026-08-31T09" },
    },
    ...overrides,
  };
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
    expect(record.silentPushes).toBe(0);
    expect(record.failedCells).toEqual([]);
    expect(record.failedCellCount).toBe(0);
    expect(record.maxDropHpa).toBe(7);
    expect(record.cellDropCount).toBe(2);
    expect(record.error).toBeNull();
  });

  it("has no max drop when no cell returned a reading", () => {
    const record = alertRunRecord({
      startedAt,
      finishedAt,
      result: result({ cellDrops: {} }),
    });

    // Null, not 0: a run that saw nothing and a run that saw a flat forecast are different answers to "why no push".
    expect(record.maxDropHpa).toBeNull();
    expect(record.cellDropCount).toBe(0);
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
    expect(record.silentPushes).toBe(0);
    expect(record.maxDropHpa).toBeNull();
    expect(record.cellDropCount).toBe(0);
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

  it("keeps the biggest drops when the cell map is capped, and the true max above it", () => {
    const cellDrops = Object.fromEntries(
      Array.from({ length: 120 }, (_, i) => [
        `cell${i}`,
        { currentHpa: 1000 + i, dropHpa: i, eventId: `E${i}` },
      ]),
    );
    const record = alertRunRecord({
      startedAt,
      finishedAt,
      result: result({ cellDrops }),
    });

    expect(Object.keys(record.cellDrops)).toHaveLength(CELL_DROP_LIMIT);
    expect(record.cellDropCount).toBe(120);
    // The cap keeps the cells that came closest to alerting, and the max is the true one either way.
    expect(record.cellDrops.cell119.dropHpa).toBe(119);
    expect(record.cellDrops.cell0).toBeUndefined();
    expect(record.maxDropHpa).toBe(119);
  });
});

describe("alertRunDocument", () => {
  it("writes snake_case fields, and only those", () => {
    const doc = alertRunDocument(
      alertRunRecord({ startedAt, finishedAt, result: result() }),
    );

    // Pinned: a camelCase key slipping back in is invisible until someone
    // reads the collection in the console and finds two spellings of it.
    expect(Object.keys(doc).sort()).toEqual([
      "cell_drop_count",
      "cell_drops",
      "cells",
      "duration_ms",
      "error",
      "failed_cell_count",
      "failed_cells",
      "finished_at",
      "max_drop_hpa",
      "pushes_sent",
      "silent_pushes",
      "started_at",
      "status",
      "users",
    ]);
  });

  it("passes the dates through for the Admin SDK to store as Timestamps", () => {
    const doc = alertRunDocument(
      alertRunRecord({ startedAt, finishedAt, result: result() }),
    );

    expect(doc.started_at).toBe(startedAt);
    expect(doc.finished_at).toBe(finishedAt);
    expect(doc.pushes_sent).toBe(1);
  });

  it("carries the silent count, so a quiet night reads as the run working", () => {
    const doc = alertRunDocument(
      alertRunRecord({
        startedAt,
        finishedAt,
        result: result({ pushesSent: 3, silentPushes: 2 }),
      }),
    );

    expect(doc.pushes_sent).toBe(3);
    expect(doc.silent_pushes).toBe(2);
  });

  it("renames the cell readings too — a nested camelCase key is just as invisible", () => {
    const doc = alertRunDocument(
      alertRunRecord({ startedAt, finishedAt, result: result() }),
    );

    expect(doc.max_drop_hpa).toBe(7);
    expect(doc.cell_drop_count).toBe(2);
    expect(doc.cell_drops).toEqual({
      u1234: { current_hpa: 1015, drop_hpa: 7, event_id: "2026-08-31T06" },
      gcpvj: { current_hpa: 1008, drop_hpa: 1.5, event_id: "2026-08-31T09" },
    });
  });
});
