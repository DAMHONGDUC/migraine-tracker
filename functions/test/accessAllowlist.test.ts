import { describe, expect, it } from "vitest";

import { premiumEmailsFrom } from "../src/core/accessAllowlist";

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
