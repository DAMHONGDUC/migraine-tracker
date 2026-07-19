import { describe, expect, it } from "vitest";

import { AlertUser, groupByGeohash } from "../src/core/grouping";

function user(uid: string, geohash5: string): AlertUser {
  return { uid, geohash5, fcmToken: `tok-${uid}`, thresholdHpa: 5, history: {} };
}

describe("groupByGeohash", () => {
  it("returns an empty map for no users", () => {
    expect(groupByGeohash([]).size).toBe(0);
  });

  it("collapses users in the same cell into one bucket (hard rule 9)", () => {
    const cells = groupByGeohash([
      user("a", "u1234"),
      user("b", "u1234"),
      user("c", "u1234"),
    ]);
    expect(cells.size).toBe(1);
    expect(cells.get("u1234")!.map((u) => u.uid)).toEqual(["a", "b", "c"]);
  });

  it("keeps distinct cells apart", () => {
    const cells = groupByGeohash([
      user("a", "u1234"),
      user("b", "gcpvj"),
      user("c", "u1234"),
    ]);
    expect(cells.size).toBe(2);
    expect(cells.get("u1234")!.map((u) => u.uid)).toEqual(["a", "c"]);
    expect(cells.get("gcpvj")!.map((u) => u.uid)).toEqual(["b"]);
  });

  it("preserves input order within a cell", () => {
    const cells = groupByGeohash([user("z", "u1234"), user("a", "u1234")]);
    expect(cells.get("u1234")!.map((u) => u.uid)).toEqual(["z", "a"]);
  });
});
