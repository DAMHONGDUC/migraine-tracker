import { generateKeyPairSync } from "node:crypto";

import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  fetchHourlyPressure,
  resetWeatherKitToken,
  weatherKitToken,
  WeatherKitCredentials,
} from "../src/weather/weatherKit";

// A real P-256 key, generated per run — the signing path is exercised for
// real without a credential ever living in the repo.
const { privateKey } = generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
  privateKeyEncoding: { type: "pkcs8", format: "pem" },
  publicKeyEncoding: { type: "spki", format: "pem" },
});

const credentials: WeatherKitCredentials = {
  privateKey,
  keyId: "KEY123",
  teamId: "TEAM456",
  serviceId: "app.dd.migraine.tracker.weather",
};

const okBody = {
  forecastHourly: {
    hours: [
      { forecastStart: "2026-07-08T12:00:00Z", pressure: 1010 },
      { forecastStart: "2026-07-08T13:00:00Z", pressure: null },
      { forecastStart: "2026-07-08T14:00:00Z", pressure: 1008 },
    ],
  },
};

const noSleep = () => Promise.resolve();

function decode(segment: string): Record<string, unknown> {
  return JSON.parse(Buffer.from(segment, "base64url").toString());
}

describe("weatherKitToken", () => {
  beforeEach(resetWeatherKitToken);

  it("puts the service id in sub and the team id in iss", () => {
    const [header, payload] = weatherKitToken(credentials).split(".");

    expect(decode(header)).toMatchObject({
      alg: "ES256",
      kid: "KEY123",
      id: "TEAM456.app.dd.migraine.tracker.weather",
    });
    expect(decode(payload)).toMatchObject({
      iss: "TEAM456",
      sub: "app.dd.migraine.tracker.weather",
    });
  });

  it("reuses the token until it is nearly expired", () => {
    const first = weatherKitToken(credentials, new Date("2026-07-08T12:00:00Z"));
    const soon = weatherKitToken(credentials, new Date("2026-07-08T12:30:00Z"));
    const later = weatherKitToken(credentials, new Date("2026-07-08T13:30:00Z"));

    expect(soon).toBe(first);
    expect(later).not.toBe(first);
  });
});

describe("fetchHourlyPressure", () => {
  beforeEach(resetWeatherKitToken);

  it("parses the hours and skips null samples", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => okBody,
    });

    const f = await fetchHourlyPressure(21, 105, {
      fetchImpl,
      sleep: noSleep,
      credentials,
    });

    expect(f.pressuresHpa).toEqual([1010, 1008]);
    expect(f.times[0].toISOString()).toBe("2026-07-08T12:00:00.000Z");
    expect(String(fetchImpl.mock.calls[0][0])).toContain(
      "dataSets=forecastHourly",
    );
  });

  it("sends the JWT as a bearer token", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => okBody,
    });

    await fetchHourlyPressure(21, 105, {
      fetchImpl,
      sleep: noSleep,
      credentials,
    });

    const headers = fetchImpl.mock.calls[0][1]?.headers as Record<
      string,
      string
    >;

    expect(headers.Authorization).toMatch(/^Bearer [\w-]+\.[\w-]+\.[\w-]+$/);
  });

  it("retries with backoff and succeeds on the third attempt", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 503, json: async () => ({}) })
      .mockRejectedValueOnce(new Error("network"))
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => okBody,
      });
    const sleep = vi.fn().mockResolvedValue(undefined);

    const f = await fetchHourlyPressure(21, 105, {
      fetchImpl,
      sleep,
      credentials,
    });

    expect(f.pressuresHpa).toHaveLength(2);
    expect(fetchImpl).toHaveBeenCalledTimes(3);
    expect(sleep).toHaveBeenNthCalledWith(1, 500);
    expect(sleep).toHaveBeenNthCalledWith(2, 1000);
  });

  it("re-signs after a 401 rather than retrying the rejected token", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => ({}) })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => okBody,
      });

    await fetchHourlyPressure(21, 105, {
      fetchImpl,
      sleep: noSleep,
      credentials,
    });

    const first = fetchImpl.mock.calls[0][1]?.headers?.Authorization;
    const second = fetchImpl.mock.calls[1][1]?.headers?.Authorization;

    expect(second).not.toBe(first);
  });

  it("throws loudly after all attempts fail", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValue({ ok: false, status: 500, json: async () => ({}) });

    await expect(
      fetchHourlyPressure(21, 105, { fetchImpl, sleep: noSleep, credentials }),
    ).rejects.toThrow(/after 3 attempts/);
  });

  it("throws on malformed bodies", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ nope: true }),
    });

    await expect(
      fetchHourlyPressure(21, 105, { fetchImpl, sleep: noSleep, credentials }),
    ).rejects.toThrow(/malformed|after 3/);
  });
});
