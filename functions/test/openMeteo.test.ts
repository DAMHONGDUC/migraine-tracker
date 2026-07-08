import { describe, expect, it, vi } from "vitest";

import { fetchHourlyPressure } from "../src/weather/openMeteo";

const okBody = {
  hourly: {
    time: ["2026-07-08T12:00", "2026-07-08T13:00", "2026-07-08T14:00"],
    surface_pressure: [1010, null, 1008],
  },
};

const noSleep = () => Promise.resolve();

describe("fetchHourlyPressure", () => {
  it("parses times as UTC and skips null samples", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => okBody,
    });
    const f = await fetchHourlyPressure(21, 105, { fetchImpl, sleep: noSleep });
    expect(f.pressuresHpa).toEqual([1010, 1008]);
    expect(f.times[0].toISOString()).toBe("2026-07-08T12:00:00.000Z");
    expect(fetchImpl).toHaveBeenCalledOnce();
    expect(String(fetchImpl.mock.calls[0][0])).toContain("forecast_days=2");
  });

  it("retries with backoff and succeeds on the third attempt", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 503, json: async () => ({}) })
      .mockRejectedValueOnce(new Error("network"))
      .mockResolvedValueOnce({ ok: true, status: 200, json: async () => okBody });
    const sleep = vi.fn().mockResolvedValue(undefined);

    const f = await fetchHourlyPressure(21, 105, { fetchImpl, sleep });
    expect(f.pressuresHpa).toHaveLength(2);
    expect(fetchImpl).toHaveBeenCalledTimes(3);
    expect(sleep).toHaveBeenNthCalledWith(1, 500);
    expect(sleep).toHaveBeenNthCalledWith(2, 1000);
  });

  it("throws loudly after all attempts fail", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue({ ok: false, status: 500, json: async () => ({}) });
    await expect(
      fetchHourlyPressure(21, 105, { fetchImpl, sleep: noSleep }),
    ).rejects.toThrow(/after 3 attempts/);
  });

  it("throws on malformed bodies", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ nope: true }),
    });
    await expect(
      fetchHourlyPressure(21, 105, { fetchImpl, sleep: noSleep }),
    ).rejects.toThrow(/malformed|after 3/);
  });
});
