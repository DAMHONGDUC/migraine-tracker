import { sign as cryptoSign } from "node:crypto";

import { defineSecret, defineString } from "firebase-functions/params";

import { HourlyForecast } from "../core/pressure";

/** The private `.p8` that signs the ES256 JWT. */
export const weatherKitPrivateKey = defineSecret("WEATHERKIT_PRIVATE_KEY");

/** From the key's filename — `AuthKey_<KEY_ID>.p8` — and the JWT's `kid`. */
export const weatherKitKeyId = defineString("WEATHERKIT_KEY_ID");

/** Membership details. The JWT's `iss`, and half of its `id` header. */
export const weatherKitTeamId = defineString("WEATHERKIT_TEAM_ID");

/** The registered Services ID, and the JWT's `sub`. */
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

/** A credential is missing, so no request was made. */
export class WeatherKitConfigError extends Error {
  constructor(readonly missing: string[]) {
    super(`weatherkit not configured: ${missing.join(", ")} empty`);
    this.name = "WeatherKitConfigError";
  }
}

/** The deploy variables behind [credentials] that carry no value. */
function missingCredentials(credentials: WeatherKitCredentials): string[] {
  const missing: string[] = [];

  if (!credentials.privateKey.trim()) missing.push("WEATHERKIT_PRIVATE_KEY");
  if (!credentials.keyId.trim()) missing.push("WEATHERKIT_KEY_ID");
  if (!credentials.teamId.trim()) missing.push("WEATHERKIT_TEAM_ID");
  if (!credentials.serviceId.trim()) missing.push("WEATHERKIT_SERVICE_ID");

  return missing;
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

/** Signs a WeatherKit JWT, reusing the last one until it is nearly expired. */
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
  // `ieee-p1363` is the raw r||s JOSE expects; Node's default is DER, which Apple rejects as a malformed signature rather than a wrong one.
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

/** Fetches 48h of hourly surface pressure from WeatherKit. */
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
  apparentTemperatureCelsius?: number;
  uvIndex?: number;
  /** Apple's own vocabulary ("Clear", "Rain"); the app maps it to a glyph. */
  conditionCode?: string;
  precipitationChancePercent?: number;
  /** Millimetres, as Apple sends it — rain and melted snow together. */
  precipitationAmountMm?: number;
  windSpeedKph?: number;
  cloudCoverPercent?: number;
  visibilityKm?: number;
}

/** Conditions right now, for the top of the weather card. */
export interface WeatherCurrent {
  /** ISO-8601, UTC. */
  time: string;
  pressureHpa?: number;
  /** Apple's own trend word: "rising", "falling", "steady". */
  pressureTrend?: string;
  temperatureCelsius?: number;
  apparentTemperatureCelsius?: number;
  humidityPercent?: number;
  uvIndex?: number;
  conditionCode?: string;
  windSpeedKph?: number;
  cloudCoverPercent?: number;
  visibilityKm?: number;
  daylight?: boolean;
}

/** One day of the multi-day forecast. */
export interface WeatherDay {
  /** ISO-8601, UTC — the day's start. */
  date: string;
  conditionCode?: string;
  temperatureMaxCelsius?: number;
  temperatureMinCelsius?: number;
  precipitationChancePercent?: number;
  /** Millimetres over the whole day. */
  precipitationAmountMm?: number;
  uvIndexMax?: number;
  /** ISO-8601, UTC. */
  sunrise?: string;
  sunset?: string;
}

/** Everything the weather card draws, from one round trip to Apple. */
export interface WeatherBundle {
  current?: WeatherCurrent;
  hours: WeatherHour[];
  days: WeatherDay[];
}

/** One request to Apple, with the token handling and the backoff. */
async function requestWeather(
  lat: number,
  lon: number,
  params: URLSearchParams,
  deps: WeatherKitDeps,
): Promise<unknown> {
  const fetchImpl = deps.fetchImpl ?? (fetch as unknown as FetchLike);
  const sleep =
    deps.sleep ?? ((ms: number) => new Promise((r) => setTimeout(r, ms)));
  const credentials = deps.credentials ?? readCredentials();
  const missing = missingCredentials(credentials);

  // Before the retry loop: an unset variable is not an outage, and three round trips to Apple cannot discover what is already known here.
  if (missing.length > 0) throw new WeatherKitConfigError(missing);

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

      return await response.json();
    } catch (error) {
      lastError = error;
    }
  }

  throw new Error(
    `weatherkit failed after ${MAX_ATTEMPTS} attempts: ${String(lastError)}`,
  );
}

/** The hourly series, optionally over an explicit window. */
export async function fetchHourlyWeather(
  lat: number,
  lon: number,
  window: { start?: Date; end?: Date } = {},
  deps: WeatherKitDeps = {},
): Promise<WeatherHour[]> {
  const params = new URLSearchParams({ dataSets: "forecastHourly" });

  if (window.start) params.set("hourlyStart", window.start.toISOString());
  if (window.end) params.set("hourlyEnd", window.end.toISOString());

  return parseHours(await requestWeather(lat, lon, params, deps));
}

/** Current conditions, the hourly series and the daily forecast together. */
export async function fetchWeatherBundle(
  lat: number,
  lon: number,
  window: { start?: Date; end?: Date } = {},
  deps: WeatherKitDeps = {},
): Promise<WeatherBundle> {
  const params = new URLSearchParams({
    dataSets: "currentWeather,forecastHourly,forecastDaily",
  });

  if (window.start) params.set("hourlyStart", window.start.toISOString());
  if (window.end) params.set("hourlyEnd", window.end.toISOString());

  const body = await requestWeather(lat, lon, params, deps);

  return {
    current: parseCurrent(body),
    hours: parseHours(body),
    days: parseDays(body),
  };
}

interface ForecastHour {
  forecastStart?: string;
  pressure?: number | null;
  humidity?: number | null;
  temperature?: number | null;
  temperatureApparent?: number | null;
  uvIndex?: number | null;
  conditionCode?: string | null;
  precipitationChance?: number | null;
  precipitationAmount?: number | null;
  windSpeed?: number | null;
  cloudCover?: number | null;
  visibility?: number | null;
}

/** Metres as Apple sends it, as the kilometres every surface says. */
function asKm(value: number | null | undefined): number | undefined {
  return value === null || value === undefined ? undefined : value / 1000;
}

/** A 0–1 fraction as Apple sends it, as the percentage every surface says. */
function asPercent(value: number | null | undefined): number | undefined {
  return value === null || value === undefined ? undefined : value * 100;
}

/** Apple's nulls and the absent key mean the same thing here: no data. */
function asNumber(value: number | null | undefined): number | undefined {
  return value === null || value === undefined ? undefined : value;
}

function asText(value: string | null | undefined): string | undefined {
  return value === null || value === undefined || value === "" ? undefined : value;
}

/** WeatherKit reports `pressure` in millibars,. */
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
      humidityPercent: asPercent(hour.humidity),
      temperatureCelsius: asNumber(hour.temperature),
      apparentTemperatureCelsius: asNumber(hour.temperatureApparent),
      uvIndex: asNumber(hour.uvIndex),
      conditionCode: asText(hour.conditionCode),
      precipitationChancePercent: asPercent(hour.precipitationChance),
      precipitationAmountMm: asNumber(hour.precipitationAmount),
      windSpeedKph: asNumber(hour.windSpeed),
      cloudCoverPercent: asPercent(hour.cloudCover),
      visibilityKm: asKm(hour.visibility),
    });
  }

  return parsed;
}

interface CurrentWeatherBody {
  asOf?: string;
  pressure?: number | null;
  pressureTrend?: string | null;
  temperature?: number | null;
  temperatureApparent?: number | null;
  humidity?: number | null;
  uvIndex?: number | null;
  conditionCode?: string | null;
  windSpeed?: number | null;
  cloudCover?: number | null;
  visibility?: number | null;
  daylight?: boolean | null;
}

/** Current conditions, or undefined when the dataset is absent. */
function parseCurrent(body: unknown): WeatherCurrent | undefined {
  const current = (body as { currentWeather?: CurrentWeatherBody })
    ?.currentWeather;

  if (!current?.asOf) return undefined;

  return {
    time: new Date(current.asOf).toISOString(),
    pressureHpa: asNumber(current.pressure),
    pressureTrend: asText(current.pressureTrend),
    temperatureCelsius: asNumber(current.temperature),
    apparentTemperatureCelsius: asNumber(current.temperatureApparent),
    humidityPercent: asPercent(current.humidity),
    uvIndex: asNumber(current.uvIndex),
    conditionCode: asText(current.conditionCode),
    windSpeedKph: asNumber(current.windSpeed),
    cloudCoverPercent: asPercent(current.cloudCover),
    visibilityKm: asKm(current.visibility),
    daylight: current.daylight ?? undefined,
  };
}

interface ForecastDay {
  forecastStart?: string;
  conditionCode?: string | null;
  temperatureMax?: number | null;
  temperatureMin?: number | null;
  precipitationChance?: number | null;
  precipitationAmount?: number | null;
  maxUvIndex?: number | null;
  sunrise?: string | null;
  sunset?: string | null;
}

/** The daily forecast, or an empty list when the dataset is absent. */
function parseDays(body: unknown): WeatherDay[] {
  const days = (body as { forecastDaily?: { days?: unknown } })?.forecastDaily
    ?.days;

  if (!Array.isArray(days)) return [];

  const parsed: WeatherDay[] = [];

  for (const day of days as ForecastDay[]) {
    if (!day?.forecastStart) continue;

    parsed.push({
      date: new Date(day.forecastStart).toISOString(),
      conditionCode: asText(day.conditionCode),
      temperatureMaxCelsius: asNumber(day.temperatureMax),
      temperatureMinCelsius: asNumber(day.temperatureMin),
      precipitationChancePercent: asPercent(day.precipitationChance),
      precipitationAmountMm: asNumber(day.precipitationAmount),
      uvIndexMax: asNumber(day.maxUvIndex),
      sunrise: day.sunrise ? new Date(day.sunrise).toISOString() : undefined,
      sunset: day.sunset ? new Date(day.sunset).toISOString() : undefined,
    });
  }

  return parsed;
}
