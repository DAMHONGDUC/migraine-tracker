import { describe, expect, it } from "vitest";

import { premiumFromEvent } from "../src/revenuecat";

describe("premiumFromEvent", () => {
  it.each(["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE"])(
    "%s grants premium",
    (type) => {
      expect(premiumFromEvent(type)).toBe(true);
    },
  );

  it("EXPIRATION revokes premium", () => {
    expect(premiumFromEvent("EXPIRATION")).toBe(false);
  });

  it("CANCELLATION does NOT revoke — access lasts until expiration", () => {
    expect(premiumFromEvent("CANCELLATION")).toBeNull();
  });

  it("unknown events change nothing", () => {
    expect(premiumFromEvent("TEST")).toBeNull();
    expect(premiumFromEvent("BILLING_ISSUE")).toBeNull();
  });
});
