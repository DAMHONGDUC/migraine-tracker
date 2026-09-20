import { describe, expect, it } from "vitest";

import { premiumEmailsFrom } from "../src/core/appConfig";

describe("premiumEmailsFrom", () => {
  it("returns nothing for an absent or empty list", () => {
    expect(premiumEmailsFrom(undefined)).toEqual([]);
    expect(premiumEmailsFrom([])).toEqual([]);
  });

  it("returns nothing for a field that is not an array", () => {
    // Typed by hand in the console: a malformed field must send no pushes
    // rather than throw the whole run.
    expect(premiumEmailsFrom("owner@example.com")).toEqual([]);
    expect(premiumEmailsFrom({ 0: "owner@example.com" })).toEqual([]);
  });

  it("trims and lower-cases, because a copy-paste does neither", () => {
    // Firebase Auth stores addresses lower-cased, so this is the spelling
    // getUserByEmail will match.
    expect(premiumEmailsFrom(["  Review@BaroEase.app  "])).toEqual([
      "review@baroease.app",
    ]);
  });

  it("de-duplicates two spellings of one address", () => {
    expect(
      premiumEmailsFrom(["owner@example.com", "Owner@Example.com"]),
    ).toEqual(["owner@example.com"]);
  });

  it("drops blanks and non-strings, keeping the rest", () => {
    expect(
      premiumEmailsFrom(["   ", 42, null, "owner@example.com"]),
    ).toEqual(["owner@example.com"]);
  });
});
