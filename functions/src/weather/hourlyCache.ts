/**
 * Rounds a coordinate to the cell the weather is cached against.
 *
 * Two jobs at once, and both matter. It bounds WeatherKit calls: everyone in
 * roughly the same place shares one fetch, so the 500k monthly quota scales
 * with populated cells rather than with users — the same reasoning as the
 * cron's geohash grouping (hard rule 10). And it means the backend never
 * stores a precise position: 0.1° is ~11km, the same order as the 5-char
 * geohash hard rule 1 allows for alert registration.
 */
export const CELL_DEGREES = 0.1;

/** How long a cached hourly series is served before it is refetched. */
export const CACHE_TTL_MINUTES = 60;

export function cellKey(lat: number, lon: number): string {
  const round = (v: number) =>
    (Math.round(v / CELL_DEGREES) * CELL_DEGREES).toFixed(1);

  return `${round(lat)}_${round(lon)}`;
}

/** The cell's centre — what actually gets sent to Apple. */
export function cellCenter(key: string): { lat: number; lon: number } {
  const [lat, lon] = key.split("_").map(Number);

  return { lat, lon };
}

export function isFresh(
  cachedAt: Date | undefined,
  now: Date,
  ttlMinutes: number = CACHE_TTL_MINUTES,
): boolean {
  if (!cachedAt) return false;

  return now.getTime() - cachedAt.getTime() < ttlMinutes * 60_000;
}
