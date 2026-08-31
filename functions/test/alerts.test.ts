import { describe, expect, it } from "vitest";

import { shouldAlert } from "../src/core/alerts";

const now = new Date("2026-07-08T12:00:00Z");
const base = {
  dropHpa: 7,
  thresholdHpa: 5,
  eventId: "2026-07-09T06",
  history: {},
  now,
};

describe("shouldAlert", () => {
  it("alerts when the drop meets the threshold and history is clean", () => {
    expect(shouldAlert(base)).toBe(true);
  });

  it("respects the exact threshold boundary", () => {
    expect(shouldAlert({ ...base, dropHpa: 5 })).toBe(true);
    expect(shouldAlert({ ...base, dropHpa: 4.99 })).toBe(false);
  });

  it("never alerts twice for the same pressure event", () => {
    expect(
      shouldAlert({
        ...base,
        history: {
          lastEventId: "2026-07-09T06",
          lastAlertAt: new Date("2026-07-06T00:00:00Z"),
        },
      }),
    ).toBe(false);
  });

  it("suppresses a second push within 12h even for a new event", () => {
    expect(
      shouldAlert({
        ...base,
        history: {
          lastEventId: "2026-07-08T03",
          // 3h ago.
          lastAlertAt: new Date("2026-07-08T09:00:00Z"),
        },
      }),
    ).toBe(false);
  });

  it("alerts for a new event once 12h have passed — the second of the day", () => {
    expect(
      shouldAlert({
        ...base,
        history: {
          lastEventId: "2026-07-08T03",
          // Midnight to noon: exactly the gap, and the boundary counts as clear.
          lastAlertAt: new Date("2026-07-08T00:00:00Z"),
        },
      }),
    ).toBe(true);
  });

  it("caps the day at two — a third event 11h after the second is still refused", () => {
    expect(
      shouldAlert({
        ...base,
        history: {
          lastEventId: "2026-07-08T03",
          lastAlertAt: new Date("2026-07-08T01:00:00Z"),
        },
      }),
    ).toBe(false);
  });

  it("uses the per-user threshold", () => {
    expect(shouldAlert({ ...base, thresholdHpa: 10 })).toBe(false);
  });
});
