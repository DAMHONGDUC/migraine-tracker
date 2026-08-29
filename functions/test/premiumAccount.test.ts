import { describe, expect, it } from "vitest";

import { premiumEmailMatches } from "../src/core/premiumAccount";

describe("premiumEmailMatches", () => {
  it("is empty when the build carries no address", () => {
    expect(premiumEmailMatches("")).toEqual([]);
    expect(premiumEmailMatches("   ")).toEqual([]);
  });

  it("asks for one spelling when the address is already lower case", () => {
    expect(premiumEmailMatches(" review@baroease.app ")).toEqual([
      "review@baroease.app",
    ]);
  });

  it("asks for both spellings when the address carries capitals", () => {
    expect(premiumEmailMatches("Review@BaroEase.app")).toEqual([
      "Review@BaroEase.app",
      "review@baroease.app",
    ]);
  });
});
