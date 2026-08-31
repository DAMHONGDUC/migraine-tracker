import { describe, expect, it } from "vitest";

import {
  isQuietHour,
  offsetFromLongitude,
  QUIET_END_HOUR,
  QUIET_START_HOUR,
} from "../src/core/quietHours";

/** 07:00 UTC. In Hanoi (+07:00) that is 14:00; in Los Angeles (-08:00) it is 23:00. */
const noonUtc = new Date("2026-07-08T07:00:00Z");

const HANOI = 7 * 60;
const LOS_ANGELES = -8 * 60;

describe("isQuietHour", () => {
  it("is quiet at night and loud in the afternoon, at the same instant", () => {
    expect(isQuietHour(noonUtc, HANOI)).toBe(false);
    expect(isQuietHour(noonUtc, LOS_ANGELES)).toBe(true);
  });

  it("opens at 22:00 local and not a minute earlier", () => {
    expect(isQuietHour(new Date("2026-07-08T14:59:00Z"), HANOI)).toBe(false);
    expect(isQuietHour(new Date("2026-07-08T15:00:00Z"), HANOI)).toBe(true);
  });

  it("closes at 07:00 local, so the alarm hour is loud again", () => {
    expect(isQuietHour(new Date("2026-07-08T23:59:00Z"), HANOI)).toBe(true);
    expect(isQuietHour(new Date("2026-07-09T00:00:00Z"), HANOI)).toBe(false);
  });

  it("holds across midnight — the window is a union, not a range", () => {
    // 02:00 in Hanoi, which is neither >= 22 nor a range 22..7 would contain.
    expect(isQuietHour(new Date("2026-07-08T19:00:00Z"), HANOI)).toBe(true);
  });

  it("reads UTC as its own zone", () => {
    expect(isQuietHour(new Date("2026-07-08T23:30:00Z"), 0)).toBe(true);
    expect(isQuietHour(new Date("2026-07-08T12:00:00Z"), 0)).toBe(false);
  });

  it("bounds the window at nine hours", () => {
    expect(QUIET_START_HOUR - QUIET_END_HOUR).toBe(15);
    expect(24 - QUIET_START_HOUR + QUIET_END_HOUR).toBe(9);
  });
});

describe("offsetFromLongitude", () => {
  it("puts Hanoi, London and Los Angeles in their own hours", () => {
    expect(offsetFromLongitude(105.85)).toBe(HANOI);
    expect(offsetFromLongitude(-0.13)).toBe(0);
    expect(offsetFromLongitude(-118.24)).toBe(LOS_ANGELES);
  });

  it("lands on whole hours — a solar offset is a guess, not a zone", () => {
    expect(offsetFromLongitude(100)).toBe(7 * 60);
    // Exactly on a boundary: JS rounds a half toward +Infinity, so -2.5 becomes -2.
    expect(offsetFromLongitude(-37.5)).toBe(-2 * 60);
  });

  it("is the guess civil time disagrees with in China, and the window absorbs it", () => {
    // Urumqi runs on Beijing time (+08:00); the sun says +06:00.
    expect(offsetFromLongitude(87.6)).toBe(6 * 60);
  });
});
