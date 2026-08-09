import { describe, expect, it, vi } from "vitest";

import {
  AlertRunDeps,
  runPressureAlerts,
  STALE_TOKEN_CODE,
} from "../src/core/alertRun";
import { AlertUser } from "../src/core/grouping";
import { DropForecast } from "../src/core/pressure";

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
  });

  it("records a failed cell and keeps processing the rest (fail loud, don't skip cohort)", async () => {
    const { deps } = harness(async (cell) => {
      if (cell === "bad00") throw new Error("open-meteo HTTP 503");
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
