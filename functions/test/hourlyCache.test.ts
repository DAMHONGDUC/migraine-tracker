import { describe, expect, it } from "vitest";

import {
  cellCenter,
  cellKey,
  isFresh,
} from "../src/weather/hourlyCache";

describe("cellKey", () => {
  it("collapses nearby coordinates onto one cell", () => {
    // ~2km apart: one fetch has to serve both, or the quota scales with users.
    expect(cellKey(21.028, 105.804)).toBe(cellKey(21.041, 105.812));
  });

  it("keeps genuinely different places apart", () => {
    expect(cellKey(21.0, 105.8)).not.toBe(cellKey(10.8, 106.7));
  });

  it("drops precision the backend has no business storing", () => {
    expect(cellKey(21.0285679, 105.8041979)).toBe("21.0_105.8");
  });

  it("round-trips to the centre that gets sent to Apple", () => {
    expect(cellCenter(cellKey(21.028, 105.804))).toEqual({
      lat: 21,
      lon: 105.8,
    });
  });

  it("handles negatives either side of the meridian and equator", () => {
    expect(cellKey(-33.87, -151.21)).toBe("-33.9_-151.2");
  });
});

describe("isFresh", () => {
  const now = new Date("2026-07-08T12:00:00Z");

  it("serves a series cached within the hour", () => {
    expect(isFresh(new Date("2026-07-08T11:30:00Z"), now)).toBe(true);
  });

  it("refetches once the hour is up", () => {
    expect(isFresh(new Date("2026-07-08T10:59:00Z"), now)).toBe(false);
  });

  it("treats a missing timestamp as stale rather than fresh", () => {
    expect(isFresh(undefined, now)).toBe(false);
  });
});
