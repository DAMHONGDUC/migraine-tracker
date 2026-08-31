import { describe, expect, it, vi } from "vitest";

import {
  AlertRunDeps,
  runPressureAlerts,
  STALE_TOKEN_CODE,
} from "../src/core/alertRun";
import { AlertUser } from "../src/core/grouping";
import { DropForecast } from "../src/core/pressure";

/** 12:00 UTC — midday for a user at UTC, so every test is loud unless it says otherwise. */
const now = new Date("2026-07-08T12:00:00Z");

function user(
  uid: string,
  geohash5: string,
  overrides: Partial<AlertUser> = {},
): AlertUser {
  return {
    uid,
    geohash5,
    fcmToken: `tok-${uid}`,
    thresholdHpa: 5,
    tzOffsetMinutes: 0,
    history: {},
    ...overrides,
  };
}

function drop(overrides: Partial<DropForecast> = {}): DropForecast {
  return {
    dropHpa: 7,
    currentHpa: 1015,
    minAt: new Date("2026-07-09T06:00:00Z"),
    eventId: "2026-07-09T06",
    ...overrides,
  };
}

/** Records every effect so tests can assert on the orchestration. */
function harness(
  fetchCellDrop: AlertRunDeps["fetchCellDrop"],
  sendPush: AlertRunDeps["sendPush"] = vi.fn(async () => {}),
) {
  const recordAlert = vi.fn(async () => {});
  const removeToken = vi.fn(async () => {});
  const deps: AlertRunDeps = {
    now,
    fetchCellDrop: vi.fn(fetchCellDrop),
    sendPush: vi.fn(sendPush),
    recordAlert,
    removeToken,
  };
  return { deps, recordAlert, removeToken };
}

describe("runPressureAlerts", () => {
  it("fetches the forecast once per cell, never per user (hard rule 9)", async () => {
    const { deps } = harness(async () => drop());
    const result = await runPressureAlerts(
      [user("a", "u1234"), user("b", "u1234"), user("c", "gcpvj")],
      deps,
    );

    expect(deps.fetchCellDrop).toHaveBeenCalledTimes(2);
    expect(result.cells).toBe(2);
    expect(result.users).toBe(3);
  });

  it("pushes and records dedupe state for users over threshold", async () => {
    const forecast = drop({ eventId: "E1" });
    const { deps, recordAlert } = harness(async () => forecast);
    const result = await runPressureAlerts([user("a", "u1234")], deps);

    expect(deps.sendPush).toHaveBeenCalledTimes(1);
    // The whole forecast, not just its id: the client's launch reconcile
    // rebuilds the notification row from the recorded drop.
    expect(recordAlert).toHaveBeenCalledWith("a", forecast, now);
    expect(result.pushesSent).toBe(1);
    expect(result.silentPushes).toBe(0);
  });

  it("sends silently to a user whose local time is the middle of the night", async () => {
    const { deps } = harness(async () => drop());
    // 12:00 UTC is 02:00 in Auckland.
    const result = await runPressureAlerts(
      [user("a", "rckq2", { tzOffsetMinutes: 14 * 60 })],
      deps,
    );

    expect(deps.sendPush).toHaveBeenCalledWith(
      expect.objectContaining({ uid: "a" }),
      expect.anything(),
      { silent: true },
    );
    expect(result.pushesSent).toBe(1);
    expect(result.silentPushes).toBe(1);
  });

  it("decides silence per user, not per cell — two zones can share a forecast", async () => {
    const { deps } = harness(async () => drop());
    const result = await runPressureAlerts(
      [
        user("day", "u1234", { tzOffsetMinutes: 0 }),
        user("night", "u1234", { tzOffsetMinutes: 14 * 60 }),
      ],
      deps,
    );

    expect(deps.fetchCellDrop).toHaveBeenCalledTimes(1);
    expect(result.pushesSent).toBe(2);
    expect(result.silentPushes).toBe(1);
  });

  it("does not count a silent push that failed to send", async () => {
    const sendPush = vi.fn(async () => {
      throw Object.assign(new Error("stale"), { code: STALE_TOKEN_CODE });
    });
    const { deps } = harness(async () => drop(), sendPush);
    const result = await runPressureAlerts(
      [user("a", "rckq2", { tzOffsetMinutes: 14 * 60 })],
      deps,
    );

    expect(result.pushesSent).toBe(0);
    expect(result.silentPushes).toBe(0);
  });

  it("skips users whose personal threshold isn't met", async () => {
    const { deps, recordAlert } = harness(async () => drop({ dropHpa: 6 }));
    const result = await runPressureAlerts(
      [user("a", "u1234", { thresholdHpa: 10 })],
      deps,
    );

    expect(deps.sendPush).not.toHaveBeenCalled();
    expect(recordAlert).not.toHaveBeenCalled();
    expect(result.pushesSent).toBe(0);
  });

  it("suppresses a repeat push for the same pressure event", async () => {
    const { deps } = harness(async () => drop({ eventId: "E1" }));
    const result = await runPressureAlerts(
      [user("a", "u1234", { history: { lastEventId: "E1" } })],
      deps,
    );

    expect(deps.sendPush).not.toHaveBeenCalled();
    expect(result.pushesSent).toBe(0);
  });

  it("does nothing for a cell with no drop in the window", async () => {
    const { deps } = harness(async () => null);
    const result = await runPressureAlerts([user("a", "u1234")], deps);

    expect(deps.sendPush).not.toHaveBeenCalled();
    expect(result.pushesSent).toBe(0);
    expect(result.failedCells).toEqual([]);
    // No reading came back, so the cell leaves no entry to read.
    expect(result.cellDrops).toEqual({});
  });

  it("keeps every cell's reading, including one that pushed to nobody", async () => {
    const { deps } = harness(async (cell) =>
      cell === "u1234"
        ? drop({ dropHpa: 1.2, currentHpa: 1008, eventId: "E1" })
        : drop({ dropHpa: 7, currentHpa: 1015, eventId: "E2" }),
    );
    const result = await runPressureAlerts(
      [user("a", "u1234"), user("b", "gcpvj")],
      deps,
    );

    // The whole point: a run that sent one push still says what the quiet cell saw.
    expect(result.cellDrops).toEqual({
      u1234: { currentHpa: 1008, dropHpa: 1.2, eventId: "E1" },
      gcpvj: { currentHpa: 1015, dropHpa: 7, eventId: "E2" },
    });
    expect(result.pushesSent).toBe(1);
  });

  it("keeps the reading of a cell whose users were all deduped", async () => {
    const { deps } = harness(async () => drop({ eventId: "E1" }));
    const result = await runPressureAlerts(
      [user("a", "u1234", { history: { lastEventId: "E1" } })],
      deps,
    );

    expect(result.pushesSent).toBe(0);
    expect(result.cellDrops.u1234.dropHpa).toBe(7);
  });

  it("leaves out a cell whose forecast failed", async () => {
    const { deps } = harness(async () => {
      throw new Error("weatherkit HTTP 503");
    });
    const result = await runPressureAlerts([user("a", "bad00")], deps);

    expect(result.failedCells).toEqual(["bad00"]);
    expect(result.cellDrops).toEqual({});
  });

  it("records a failed cell and keeps processing the rest (fail loud, don't skip cohort)", async () => {
    const { deps } = harness(async (cell) => {
      if (cell === "bad00") throw new Error("weatherkit HTTP 503");
      return drop();
    });
    const result = await runPressureAlerts(
      [user("a", "bad00"), user("b", "good0")],
      deps,
    );

    expect(result.failedCells).toEqual(["bad00"]);
    // The healthy cell still got its push.
    expect(deps.sendPush).toHaveBeenCalledTimes(1);
    expect(result.pushesSent).toBe(1);
  });

  it("drops a stale FCM token and doesn't count it as sent", async () => {
    const sendPush = vi.fn(async () => {
      throw Object.assign(new Error("stale"), { code: STALE_TOKEN_CODE });
    });
    const { deps, recordAlert, removeToken } = harness(
      async () => drop(),
      sendPush,
    );
    const result = await runPressureAlerts([user("a", "u1234")], deps);

    expect(removeToken).toHaveBeenCalledWith("a");
    expect(recordAlert).not.toHaveBeenCalled();
    expect(result.pushesSent).toBe(0);
  });

  it("logs other push failures without dropping the token", async () => {
    const sendPush = vi.fn(async () => {
      throw Object.assign(new Error("internal"), { code: "messaging/internal" });
    });
    const { deps, recordAlert, removeToken } = harness(
      async () => drop(),
      sendPush,
    );
    const logError = vi.fn();
    const result = await runPressureAlerts([user("a", "u1234")], {
      ...deps,
      logError,
    });

    expect(removeToken).not.toHaveBeenCalled();
    expect(recordAlert).not.toHaveBeenCalled();
    expect(logError).toHaveBeenCalledWith(
      "push failed",
      expect.objectContaining({ uid: "a" }),
    );
    expect(result.pushesSent).toBe(0);
  });

  it("pushes to every eligible user in a shared cell after one fetch", async () => {
    const { deps } = harness(async () => drop());
    const result = await runPressureAlerts(
      [user("a", "u1234"), user("b", "u1234")],
      deps,
    );

    expect(deps.fetchCellDrop).toHaveBeenCalledTimes(1);
    expect(deps.sendPush).toHaveBeenCalledTimes(2);
    expect(result.pushesSent).toBe(2);
  });
});
