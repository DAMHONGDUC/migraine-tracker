/** Rounds a coordinate to the cell the weather is cached against. */
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
