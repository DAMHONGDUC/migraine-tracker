import { randomBytes } from "node:crypto";

import { describe, expect, it, vi } from "vitest";

import {
  isWellFormedKey,
  resolveSyncKey,
  SYNC_KEY_BYTES,
  SyncKeyDeps,
} from "../src/core/syncKey";

const now = new Date("2026-07-08T12:00:00Z");

function aKey(): string {
  return randomBytes(SYNC_KEY_BYTES).toString("base64");
}

/** A store backed by a plain map, standing in for the Firestore transaction. */
function harness(seed: Record<string, string> = {}) {
  const stored = new Map<string, string>(Object.entries(seed));
  const save = vi.fn(async (uid: string, key: string) => {
    stored.set(uid, key);
  });
  const deps: SyncKeyDeps = {
    now,
    load: vi.fn(async (uid: string) => stored.get(uid) ?? null),
    save,
    generateKey: vi.fn(aKey),
  };
  return { deps, save, stored };
}

describe("resolveSyncKey", () => {
  it("mints a usable key on first use and stores it", async () => {
    const { deps, save, stored } = harness();

    const key = await resolveSyncKey("u1", deps);

    expect(isWellFormedKey(key)).toBe(true);
    expect(Buffer.from(key, "base64")).toHaveLength(SYNC_KEY_BYTES);
    expect(save).toHaveBeenCalledOnce();
    expect(stored.get("u1")).toBe(key);
  });

  it("returns the same key every call after the first", async () => {
    const { deps, save } = harness();

    const first = await resolveSyncKey("u1", deps);
    const second = await resolveSyncKey("u1", deps);

    // A second key would strand everything encrypted with the first.
    expect(second).toBe(first);
    expect(save).toHaveBeenCalledOnce();
  });

  it("gives two users different keys", async () => {
    const { deps } = harness();

    expect(await resolveSyncKey("u1", deps)).not.toBe(
      await resolveSyncKey("u2", deps),
    );
  });

  it("refuses to replace a stored key it cannot parse", async () => {
    const { deps, save } = harness({ u1: "not-a-key" });

    // Minting a replacement would make the user's whole uploaded history
    // undecryptable — fail loud instead.
    await expect(resolveSyncKey("u1", deps)).rejects.toThrow(/malformed/);
    expect(save).not.toHaveBeenCalled();
  });

  it("refuses a key of the wrong length from the generator", async () => {
    const { deps, save } = harness();
    deps.generateKey = () => randomBytes(16).toString("base64");

    await expect(resolveSyncKey("u1", deps)).rejects.toThrow(/malformed/);
    expect(save).not.toHaveBeenCalled();
  });

  it("rejects a missing uid", async () => {
    const { deps } = harness();

    await expect(resolveSyncKey("", deps)).rejects.toThrow(/uid required/);
  });
});

describe("isWellFormedKey", () => {
  it("accepts exactly a 32-byte base64 key", () => {
    expect(isWellFormedKey(aKey())).toBe(true);
  });

  it("rejects anything else", () => {
    expect(isWellFormedKey(randomBytes(31).toString("base64"))).toBe(false);
    expect(isWellFormedKey(randomBytes(33).toString("base64"))).toBe(false);
    expect(isWellFormedKey("")).toBe(false);
    expect(isWellFormedKey(null)).toBe(false);
    expect(isWellFormedKey(42)).toBe(false);
  });
});
