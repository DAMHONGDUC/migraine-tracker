import { describe, expect, it } from "vitest";

import {
  ownedId,
  planMigration,
  RECORD_ID_FIELD,
} from "../src/core/ownedIdMigration";

const at = (ms: number) => ({ toMillis: () => ms });

describe("planMigration", () => {
  it("moves a bare-id document under its owner, keeping the record id", () => {
    const updatedAt = at(1);
    const step = planMigration("2026-09-24", { userId: "alice", updatedAt }, null);

    expect(step).toEqual({
      kind: "move",
      to: "alice_2026-09-24",
      data: { userId: "alice", updatedAt, [RECORD_ID_FIELD]: "2026-09-24" },
    });
  });

  it("leaves a document that already has an owned id", () => {
    expect(planMigration("alice_2026-09-24", { userId: "alice" }, null)).toEqual({
      kind: "skip",
      reason: "alreadyOwned",
    });
  });

  it("leaves a document with no owner rather than guessing one", () => {
    expect(planMigration("x", { updatedAt: at(1) }, null)).toEqual({
      kind: "skip",
      reason: "noOwner",
    });
  });

  it("only drops the legacy copy when the owned one is newer", () => {
    expect(
      planMigration("a1", { userId: "alice", updatedAt: at(1) }, { updatedAt: at(2) }),
    ).toEqual({ kind: "dropLegacy" });
  });

  // An old build can still update the legacy copy after a new build wrote the owned one.
  it("moves the legacy copy over the owned one when the legacy is newer", () => {
    const step = planMigration("a1", { userId: "alice", updatedAt: at(3) }, { updatedAt: at(2) });

    expect(step.kind).toBe("move");
  });

  it("matches the app's SdId.owned", () => {
    expect(ownedId("alice", "2026-09-24")).toBe("alice_2026-09-24");
  });
});
