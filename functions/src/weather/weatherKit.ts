import { sign as cryptoSign } from "node:crypto";

import { defineSecret, defineString } from "firebase-functions/params";

import { HourlyForecast } from "../core/pressure";

/**
 * The private `.p8` that signs the ES256 JWT. A secret, unlike the three
 * identifiers below — those name things, this one proves we are us.
 *
 * Any function calling into this module must list it in its own `secrets`,
 * or the value is empty at runtime and every request 401s.
 */
export const weatherKitPrivateKey = defineSecret("WEATHERKIT_PRIVATE_KEY");

/** From the key's filename — `AuthKey_<KEY_ID>.p8` — and the JWT's `kid`. */
export const weatherKitKeyId = defineString("WEATHERKIT_KEY_ID");

/** Membership details. The JWT's `iss`, and half of its `id` header. */
export const weatherKitTeamId = defineString("WEATHERKIT_TEAM_ID");

/**
 * The registered Services ID, and the JWT's `sub`.
 *
 * **Not the app's Bundle ID.** A Services ID is its own identifier type, and
 * a bundle id in its place returns a bare 401 with nothing saying why.
 */
export const weatherKitServiceId = defineString("WEATHERKIT_SERVICE_ID");

const MAX_ATTEMPTS = 3;

/** An hour, matching the token's own lifetime. */
const TOKEN_TTL_SECONDS = 3600;

/** Re-signed a minute early, so a token cannot expire mid-request. */
const TOKEN_SKEW_SECONDS = 60;

type FetchLike = (
  url: string,
  init?: { headers?: Record<string, string> },
) => Promise<{
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
}>;

export interface WeatherKitCredentials {
  privateKey: string;
  keyId: string;
  teamId: string;
  serviceId: string;
}

let cachedToken: { value: string; expiresAt: number } | undefined;

/** Drops the memoized JWT. For tests, and for a credential rotation. */
export function resetWeatherKitToken(): void {
  cachedToken = undefined;
}

function base64Url(input: Buffer | string): string {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

/**
 * Signs a WeatherKit JWT, reusing the last one until it is nearly expired.
 *
 * Signing per request would be wasted CPU on every cron run — the token is
 * bound to the team and the service, never to the coordinates being asked
 * about, so one covers the whole run.
 */
export function weatherKitToken(
  credentials: WeatherKitCredentials,
  now: Date = new Date(),
): string {
  const issuedAt = Math.floor(now.getTime() / 1000);

  if (cachedToken && cachedToken.expiresAt - TOKEN_SKEW_SECONDS > issuedAt) {
    return cachedToken.value;
  }

  const expiresAt = issuedAt + TOKEN_TTL_SECONDS;
  const header = {
    alg: "ES256",
    kid: credentials.keyId,
    // Apple wants team and service joined here as well as in the claims.
    id: `${credentials.teamId}.${credentials.serviceId}`,
    typ: "JWT",
  };
  const payload = {
    iss: credentials.teamId,
    sub: credentials.serviceId,
    iat: issuedAt,
    exp: expiresAt,
  };
  const signingInput = `${base64Url(JSON.stringify(header))}.${base64Url(
    JSON.stringify(payload),
  )}`;
  // `ieee-p1363` is the raw r||s JOSE expects; Node's default is DER, which
  // Apple rejects as a malformed signature rather than a wrong one.
  const signature = cryptoSign("sha256", Buffer.from(signingInput), {
    key: credentials.privateKey,
    dsaEncoding: "ieee-p1363",
  });
  const token = `${signingInput}.${base64Url(signature)}`;

  cachedToken = { value: token, expiresAt };

  return token;
}

function readCredentials(): WeatherKitCredentials {
  return {
    privateKey: weatherKitPrivateKey.value(),
    keyId: weatherKitKeyId.value(),
    teamId: weatherKitTeamId.value(),
    serviceId: weatherKitServiceId.value(),
  };
}

/**
 * Fetches 48h of hourly surface pressure from WeatherKit. Retries with
 * exponential backoff and THROWS after the final failure — weather errors
 * must fail loud, never silently skip a cohort (hard rule: Cloud Functions).
 *
 * Same signature and same contract as the Open-Meteo source it replaced, so
 * the geohash grouping, the dedupe window and the alert maths above it are
 * untouched by the provider swap.
 */
export async function fetchHourlyPressure(
  lat: number,
  lon: number,
  deps: WeatherKitDeps = {},
): Promise<HourlyForecast> {
  const hours = await fetchHourlyWeather(lat, lon, {}, deps);
  const times: Date[] = [];
  const pressuresHpa: number[] = [];

  for (const hour of hours) {
    times.push(new Date(hour.time));
    pressuresHpa.push(hour.pressureHpa);
  }

  return { times, pressuresHpa };
}

export interface WeatherKitDeps {
  fetchImpl?: FetchLike;
  sleep?: (ms: number) => Promise<void>;
  credentials?: WeatherKitCredentials;
  now?: Date;
}

/** One hour of the forecast, in the units the app already speaks. */
export interface WeatherHour {
  /** ISO-8601, UTC. */
  time: string;
  pressureHpa: number;
  humidityPercent?: number;
  temperatureCelsius?: number;
}

/**
 * The hourly series, optionally over an explicit window.
 *
 * `hourlyStart`/`hourlyEnd` are what let the app backfill an attack logged
 * offline days ago with the weather *at its start time* — without them
 * WeatherKit answers from the current hour forward, which cannot describe
 * something that already happened.
 */
export async function fetchHourlyWeather(
  lat: number,
  lon: number,
  window: { start?: Date; end?: Date } = {},
  deps: WeatherKitDeps = {},
): Promise<WeatherHour[]> {
  const fetchImpl = deps.fetchImpl ?? (fetch as unknown as FetchLike);
  const sleep =
    deps.sleep ?? ((ms: number) => new Promise((r) => setTimeout(r, ms)));
  const credentials = deps.credentials ?? readCredentials();
  const params = new URLSearchParams({ dataSets: "forecastHourly" });

  if (window.start) params.set("hourlyStart", window.start.toISOString());
  if (window.end) params.set("hourlyEnd", window.end.toISOString());

  const url =
    "https://weatherkit.apple.com/api/v1/weather/en" +
    `/${lat}/${lon}?${params.toString()}`;

  let lastError: unknown;
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    if (attempt > 0) await sleep(500 * 2 ** (attempt - 1));
    try {
      const token = weatherKitToken(credentials, deps.now);
      const response = await fetchImpl(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        // A rejected token is never fixed by retrying with the same one.
        if (response.status === 401) resetWeatherKitToken();
        throw new Error(`weatherkit HTTP ${response.status}`);
      }

      return parseHours(await response.json());
    } catch (error) {
      lastError = error;
    }
  }

  throw new Error(
    `weatherkit failed after ${MAX_ATTEMPTS} attempts: ${String(lastError)}`,
  );
}

interface ForecastHour {
  forecastStart?: string;
  pressure?: number | null;
  humidity?: number | null;
  temperature?: number | null;
}

/**
 * WeatherKit reports `pressure` in millibars, which is hPa — the same unit
 * Open-Meteo returned and the unit the alert threshold is already in, so
 * nothing downstream converts.
 *
 * `humidity` is the one that does convert: Apple sends a 0–1 fraction and
 * every surface in the app says a percentage.
 */
function parseHours(body: unknown): WeatherHour[] {
  const hours = (body as { forecastHourly?: { hours?: unknown } })
    ?.forecastHourly?.hours;

  if (!Array.isArray(hours)) {
    throw new Error("weatherkit: malformed body");
  }

  const parsed: WeatherHour[] = [];

  for (const hour of hours as ForecastHour[]) {
    const pressure = hour?.pressure;

    if (pressure === null || pressure === undefined) continue;
    if (!hour.forecastStart) continue;

    parsed.push({
      time: new Date(hour.forecastStart).toISOString(),
      pressureHpa: pressure,
      humidityPercent:
        hour.humidity === null || hour.humidity === undefined
          ? undefined
          : hour.humidity * 100,
      temperatureCelsius: hour.temperature ?? undefined,
    });
  }

  return parsed;
}
