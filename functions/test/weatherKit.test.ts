import { generateKeyPairSync } from "node:crypto";

import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  fetchHourlyPressure,
  fetchWeatherBundle,
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

  it("names the empty credentials instead of asking Apple", async () => {
    const fetchImpl = vi.fn();

    await expect(
      fetchHourlyPressure(21, 105, {
        fetchImpl,
        sleep: noSleep,
        credentials: { ...credentials, keyId: "", teamId: "  " },
      }),
    ).rejects.toThrow(
      /WEATHERKIT_KEY_ID, WEATHERKIT_TEAM_ID empty/,
    );
    expect(fetchImpl).not.toHaveBeenCalled();
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

const bundleBody = {
  currentWeather: {
    asOf: "2026-07-08T12:00:00Z",
    pressure: 1009,
    pressureTrend: "falling",
    temperature: 28.4,
    temperatureApparent: 31.2,
    humidity: 0.74,
    uvIndex: 7,
    conditionCode: "PartlyCloudy",
    windSpeed: 12.5,
    cloudCover: 0.4,
    visibility: 16000,
    daylight: true,
  },
  forecastHourly: {
    hours: [
      {
        forecastStart: "2026-07-08T12:00:00Z",
        pressure: 1009,
        temperature: 28.4,
        temperatureApparent: 31.2,
        humidity: 0.74,
        uvIndex: 7,
        conditionCode: "PartlyCloudy",
        precipitationChance: 0.2,
        precipitationAmount: 1.4,
        windSpeed: 12.5,
        cloudCover: 0.4,
        visibility: 16000,
      },
    ],
  },
  forecastDaily: {
    days: [
      {
        forecastStart: "2026-07-08T00:00:00Z",
        conditionCode: "Rain",
        temperatureMax: 31,
        temperatureMin: 24,
        precipitationChance: 0.8,
        precipitationAmount: 12.5,
        maxUvIndex: 9,
        sunrise: "2026-07-08T22:15:00Z",
        sunset: "2026-07-09T11:30:00Z",
      },
    ],
  },
};

describe("fetchWeatherBundle", () => {
  beforeEach(resetWeatherKitToken);

  function respond(body: unknown) {
    return vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => body,
    });
  }

  it("asks for all three datasets in one request", async () => {
    const fetchImpl = respond(bundleBody);

    await fetchWeatherBundle(21, 105, {}, { fetchImpl, sleep: noSleep, credentials });

    const url = String(fetchImpl.mock.calls[0][0]);

    expect(fetchImpl).toHaveBeenCalledTimes(1);
    expect(decodeURIComponent(url)).toContain(
      "dataSets=currentWeather,forecastHourly,forecastDaily",
    );
  });

  it("converts Apple's fractions to percentages and metres to kilometres", async () => {
    const bundle = await fetchWeatherBundle(
      21,
      105,
      {},
      { fetchImpl: respond(bundleBody), sleep: noSleep, credentials },
    );

    expect(bundle.current).toMatchObject({
      pressureHpa: 1009,
      pressureTrend: "falling",
      humidityPercent: 74,
      cloudCoverPercent: 40,
      visibilityKm: 16,
      uvIndex: 7,
      daylight: true,
    });
    expect(bundle.hours[0]).toMatchObject({
      precipitationChancePercent: 20,
      // Millimetres straight through: the one precipitation field Apple
      // already sends in the unit the app shows.
      precipitationAmountMm: 1.4,
      apparentTemperatureCelsius: 31.2,
      conditionCode: "PartlyCloudy",
      // Hourly visibility too, not just current: the weather card offers it
      // as one of the readings its dropdown switches between.
      visibilityKm: 16,
    });
    expect(bundle.days[0]).toMatchObject({
      temperatureMaxCelsius: 31,
      temperatureMinCelsius: 24,
      precipitationChancePercent: 80,
      precipitationAmountMm: 12.5,
      uvIndexMax: 9,
    });
  });

  it("still returns the hourly series when Apple omits the other datasets", async () => {
    const bundle = await fetchWeatherBundle(
      21,
      105,
      {},
      { fetchImpl: respond(okBody), sleep: noSleep, credentials },
    );

    expect(bundle.current).toBeUndefined();
    expect(bundle.days).toEqual([]);
    expect(bundle.hours).toHaveLength(2);
  });

  it("reads a null field as absent rather than as zero", async () => {
    const bundle = await fetchWeatherBundle(
      21,
      105,
      {},
      {
        fetchImpl: respond({
          currentWeather: {
            asOf: "2026-07-08T12:00:00Z",
            humidity: null,
            uvIndex: null,
            conditionCode: null,
            visibility: null,
          },
          forecastHourly: { hours: [] },
        }),
        sleep: noSleep,
        credentials,
      },
    );

    expect(bundle.current).toMatchObject({ time: "2026-07-08T12:00:00.000Z" });
    expect(bundle.current?.humidityPercent).toBeUndefined();
    expect(bundle.current?.uvIndex).toBeUndefined();
    expect(bundle.current?.conditionCode).toBeUndefined();
    expect(bundle.current?.visibilityKm).toBeUndefined();
  });
});
