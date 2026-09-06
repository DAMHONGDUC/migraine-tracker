import { describe, expect, it } from "vitest";

import { premiumEmailsFrom, premiumEnabledFrom } from "../src/core/appConfig";

describe("premiumEmailsFrom", () => {
  it("returns nothing for an empty list", () => {
    expect(premiumEmailsFrom([])).toEqual([]);
  });

  it("keeps only rows where premium is exactly true", () => {
    expect(
      premiumEmailsFrom([
        { id: "yes@baroease.app", premium: true },
        { id: "no@baroease.app", premium: false },
        { id: "missing@baroease.app", premium: undefined },
        // A row whose flag was typed as a string is not a grant.
        { id: "stringy@baroease.app", premium: "true" },
      ]),
    ).toEqual(["yes@baroease.app"]);
  });

  it("normalises the spelling the console produced", () => {
    expect(
      premiumEmailsFrom([{ id: "  Review@BaroEase.app  ", premium: true }]),
    ).toEqual(["review@baroease.app"]);
  });

  it("de-duplicates rows that normalise to the same address", () => {
    expect(
      premiumEmailsFrom([
        { id: "Review@BaroEase.app", premium: true },
        { id: "review@baroease.app", premium: true },
      ]),
    ).toEqual(["review@baroease.app"]);
  });

  it("drops a row whose id is blank", () => {
    expect(premiumEmailsFrom([{ id: "   ", premium: true }])).toEqual([]);
  });
});

describe("premiumEnabledFrom", () => {
  it("is on when the flags document does not exist at all", () => {
    // The normal state of a project nobody has touched: the switch has never
    // been thrown, so premium behaves as it did before the switch existed.
    expect(premiumEnabledFrom(undefined)).toBe(true);
  });

  it("is on when the document exists without the field", () => {
    expect(premiumEnabledFrom({ something_else: true })).toBe(true);
  });

  it("is off only for a real false", () => {
    expect(premiumEnabledFrom({ enable_premium: false })).toBe(false);
  });

  it("ignores a string typed into the console", () => {
    // Same trap as the grant fields, in the opposite direction: "false" typed
    // as text would read as "switched off" to a truthiness check and quietly
    // stop every alert.
    expect(premiumEnabledFrom({ enable_premium: "false" })).toBe(true);
  });

  it("is on for an explicit true", () => {
    expect(premiumEnabledFrom({ enable_premium: true })).toBe(true);
  });
});
