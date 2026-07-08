import { HourlyForecast } from "../core/pressure";

type FetchLike = (url: string) => Promise<{
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
}>;

const MAX_ATTEMPTS = 3;

/**
 * Fetches 48h of hourly surface pressure. Retries with exponential backoff
 * and THROWS after the final failure — weather errors must fail loud, never
 * silently skip a cohort (hard rule: Cloud Functions).
 */
export async function fetchHourlyPressure(
  lat: number,
  lon: number,
  deps: {
    fetchImpl?: FetchLike;
    sleep?: (ms: number) => Promise<void>;
  } = {},
): Promise<HourlyForecast> {
  const fetchImpl = deps.fetchImpl ?? (fetch as unknown as FetchLike);
  const sleep =
    deps.sleep ?? ((ms: number) => new Promise((r) => setTimeout(r, ms)));

  const url =
    "https://api.open-meteo.com/v1/forecast" +
    `?latitude=${lat}&longitude=${lon}` +
    "&hourly=surface_pressure&forecast_days=2&timezone=UTC";

  let lastError: unknown;
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    if (attempt > 0) await sleep(500 * 2 ** (attempt - 1));
    try {
      const response = await fetchImpl(url);
      if (!response.ok) {
        throw new Error(`open-meteo HTTP ${response.status}`);
      }
      return parseForecast(await response.json());
    } catch (error) {
      lastError = error;
    }
  }
  throw new Error(
    `open-meteo failed after ${MAX_ATTEMPTS} attempts: ${String(lastError)}`,
  );
}

function parseForecast(body: unknown): HourlyForecast {
  const hourly = (body as { hourly?: unknown }).hourly as
    | { time?: string[]; surface_pressure?: (number | null)[] }
    | undefined;
  if (!hourly?.time || !hourly.surface_pressure) {
    throw new Error("open-meteo: malformed body");
  }
  const times: Date[] = [];
  const pressuresHpa: number[] = [];
  for (let i = 0; i < hourly.time.length; i++) {
    const pressure = hourly.surface_pressure[i];
    if (pressure === null || pressure === undefined) continue;
    times.push(new Date(`${hourly.time[i]}Z`));
    pressuresHpa.push(pressure);
  }
  return { times, pressuresHpa };
}
