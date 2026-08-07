import { describe, expect, it, vi } from "vitest";

import {
  AccountTeardownDeps,
  SYNCED_COLLECTIONS,
  tearDownAccount,
} from "../src/core/accountTeardown";

/** Records the order every step ran in, which is the part that matters. */
function harness(overrides: Partial<AccountTeardownDeps> = {}) {
  const order: string[] = [];
  const deps: AccountTeardownDeps = {
    deleteRecords: vi.fn(async (_uid: string, collection: string) => {
      order.push(`records:${collection}`);
      return 2;
    }),
    deleteUserDoc: vi.fn(async () => {
      order.push("userDoc");
    }),
    deleteSyncKey: vi.fn(async () => {
      order.push("syncKey");
    }),
    deleteAuthUser: vi.fn(async () => {
      order.push("authUser");
    }),
    logInfo: vi.fn(),
    ...overrides,
  };
  return { deps, order };
}

describe("tearDownAccount", () => {
  it("clears every synced collection", async () => {
    const { deps, order } = harness();

    const result = await tearDownAccount("u1", deps);

    for (const collection of SYNCED_COLLECTIONS) {
      expect(order).toContain(`records:${collection}`);
    }
    expect(result.deleted).toBe(SYNCED_COLLECTIONS.length * 2);
  });

  it("deletes the auth user last", async () => {
    const { deps, order } = harness();

    await tearDownAccount("u1", deps);

    // Deleting the account first would leave every later step unauthorised
    // and the data orphaned, with nobody left who could ask for it to go.
    expect(order[order.length - 1]).toBe("authUser");
  });

  it("deletes the sync key, which no client ever could", async () => {
    const { deps } = harness();

    await tearDownAccount("u1", deps);

    // Rules deny sync_keys to everyone; left behind it would outlive the
    // account that owned it with no way to reach it.
    expect(deps.deleteSyncKey).toHaveBeenCalledWith("u1");
  });

  it("stops at the first failure rather than half-tearing-down", async () => {
    const { deps, order } = harness({
      deleteUserDoc: vi.fn(async () => {
        throw new Error("firestore down");
      }),
    });

    await expect(tearDownAccount("u1", deps)).rejects.toThrow("firestore down");

    // The auth user survives, so the caller still has an account to retry
    // with — the alternative is data nobody can ever reach again.
    expect(order).not.toContain("authUser");
    expect(deps.deleteAuthUser).not.toHaveBeenCalled();
  });

  it("rejects a missing uid", async () => {
    const { deps } = harness();

    await expect(tearDownAccount("", deps)).rejects.toThrow(/uid required/);
    expect(deps.deleteAuthUser).not.toHaveBeenCalled();
  });
});
