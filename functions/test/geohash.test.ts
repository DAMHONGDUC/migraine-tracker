import { describe, expect, it } from "vitest";

import { geohashCenter } from "../src/core/geohash";

describe("geohashCenter", () => {
  it("decodes the classic ezs42 example", () => {
    const { lat, lon } = geohashCenter("ezs42");
    expect(lat).toBeCloseTo(42.605, 2);
    expect(lon).toBeCloseTo(-5.603, 2);
  });

  it("decodes a Hanoi 5-char hash to within the cell", () => {
    // w7er8 covers central Hanoi (~21.03, 105.85).
    const { lat, lon } = geohashCenter("w7er8");
    expect(lat).toBeGreaterThan(20.9);
    expect(lat).toBeLessThan(21.2);
    expect(lon).toBeGreaterThan(105.7);
    expect(lon).toBeLessThan(106.0);
  });

  it("rejects invalid characters", () => {
    expect(() => geohashCenter("ab!de")).toThrow(/invalid/);
    expect(() => geohashCenter("")).toThrow(/empty/);
  });
});
