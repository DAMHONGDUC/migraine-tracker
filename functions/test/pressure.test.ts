import { describe, expect, it } from "vitest";

import { HourlyForecast, maxDrop24h } from "../src/core/pressure";

function forecast(start: Date, pressures: number[]): HourlyForecast {
  return {
    times: pressures.map(
      (_, i) => new Date(start.getTime() + i * 60 * 60 * 1000),
    ),
    pressuresHpa: pressures,
  };
}

const now = new Date("2026-07-08T12:00:00Z");

describe("maxDrop24h", () => {
  it("finds the deepest drop within the next 24h", () => {
    // now = index 0 at 1013; minimum 1005 at +6h; recovers after.
    const f = forecast(now, [1013, 1011, 1009, 1007, 1006, 1005.5, 1005, 1008, 1010]);
    const drop = maxDrop24h(f, now);
    expect(drop).not.toBeNull();
    expect(drop!.dropHpa).toBeCloseTo(8);
    expect(drop!.currentHpa).toBe(1013);
    expect(drop!.minAt.toISOString()).toBe("2026-07-08T18:00:00.000Z");
    expect(drop!.eventId).toBe("2026-07-08T18");
  });

  it("ignores samples beyond the 24h window", () => {
    // Big crash at +30h must not count; within 24h it only falls 2 hPa.
    const pressures = Array(31).fill(1013);
    for (let i = 1; i <= 24; i++) pressures[i] = 1011;
    pressures[30] = 990;
    const drop = maxDrop24h(forecast(now, pressures), now);
    expect(drop!.dropHpa).toBeCloseTo(2);
  });

  it("reports negative drop when pressure only rises", () => {
    const drop = maxDrop24h(forecast(now, [1005, 1008, 1011, 1013]), now);
    expect(drop!.dropHpa).toBeLessThan(0);
  });

  it("returns null when now is outside the forecast", () => {
    const f = forecast(new Date("2026-07-01T00:00:00Z"), [1010, 1010]);
    expect(maxDrop24h(f, now)).toBeNull();
  });

  it("returns null when there are no samples after now", () => {
    const f = forecast(now, [1010]);
    expect(maxDrop24h(f, now)).toBeNull();
  });

  // Telling someone at 09:00 that a 15:00 front is arriving "now" is the fastest way to have the alert switched off.
  it("starts the fall at the crest, not at now", () => {
    const times = [0, 1, 2, 3, 4, 5, 6].map(
      (h) => new Date(`2026-07-09T0${h}:00:00Z`),
    );
    // Still climbing for three hours, then falling hard.
    const drop = maxDrop24h(
      { times, pressuresHpa: [1010, 1012, 1014, 1016, 1010, 1005, 1004] },
      new Date("2026-07-09T00:00:00Z"),
    );

    expect(drop).not.toBeNull();
    expect(drop!.startsAt).toEqual(new Date("2026-07-09T03:00:00Z"));
  });

  it("starts the fall at now when the pressure only ever falls", () => {
    const times = [0, 1, 2, 3].map((h) => new Date(`2026-07-09T0${h}:00:00Z`));
    const drop = maxDrop24h(
      { times, pressuresHpa: [1015, 1012, 1009, 1005] },
      new Date("2026-07-09T00:00:00Z"),
    );

    expect(drop!.startsAt).toEqual(new Date("2026-07-09T00:00:00Z"));
  });
});
