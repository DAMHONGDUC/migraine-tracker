export interface HourlyForecast {
  /** UTC hourly timestamps, ascending. */
  times: Date[];
  pressuresHpa: number[];
}

export interface DropForecast {
  /** Positive = pressure will fall by this much within the next 24h. */
  dropHpa: number;
  currentHpa: number;
  minAt: Date;
  /** When the fall itself begins: the highest hour between now and the trough. A drop forecast for Friday is not happening on Wednesday, and the user is told twice for that reason. */
  startsAt: Date;
  /** Identifies the pressure event (the UTC hour of the forecast minimum) so the same front never triggers two pushes to one user. */
  eventId: string;
}

const NEAREST_TOLERANCE_MS = 90 * 60 * 1000;

/** The worst (largest) forecast pressure drop within 24h of [now], relative to the pressure at [now]. */
export function maxDrop24h(
  forecast: HourlyForecast,
  now: Date,
): DropForecast | null {
  const { times, pressuresHpa } = forecast;
  if (times.length !== pressuresHpa.length || times.length === 0) return null;

  let nowIndex = -1;
  let best = Infinity;
  for (let i = 0; i < times.length; i++) {
    const distance = Math.abs(times[i].getTime() - now.getTime());
    if (distance < best) {
      best = distance;
      nowIndex = i;
    }
  }
  if (nowIndex === -1 || best > NEAREST_TOLERANCE_MS) return null;

  const currentHpa = pressuresHpa[nowIndex];
  const windowEnd = now.getTime() + 24 * 60 * 60 * 1000;
  let minHpa = Infinity;
  let minAt: Date | null = null;
  let minIndex = -1;
  for (let i = nowIndex + 1; i < times.length; i++) {
    if (times[i].getTime() > windowEnd) break;
    if (pressuresHpa[i] < minHpa) {
      minHpa = pressuresHpa[i];
      minAt = times[i];
      minIndex = i;
    }
  }
  if (minAt === null) return null;

  return {
    dropHpa: currentHpa - minHpa,
    currentHpa,
    minAt,
    startsAt: crestBefore(forecast, nowIndex, minIndex),
    eventId: minAt.toISOString().slice(0, 13), // e.g. "2026-07-09T06"
  };
}

/**
 * The hour the fall starts from: the highest pressure between now and the
 * trough, inclusive of now.
 *
 * A pressure that is still climbing for six hours before it turns has not
 * started falling, and telling someone at 09:00 that a 15:00 front is arriving
 * "now" is the fastest way to have the alert switched off.
 */
function crestBefore(
  forecast: HourlyForecast,
  nowIndex: number,
  minIndex: number,
): Date {
  const { times, pressuresHpa } = forecast;
  let crestIndex = nowIndex;

  for (let i = nowIndex; i < minIndex; i++) {
    if (pressuresHpa[i] > pressuresHpa[crestIndex]) crestIndex = i;
  }
  return times[crestIndex];
}
