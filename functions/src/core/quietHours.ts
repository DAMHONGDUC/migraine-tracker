/**
 * The user's local night. A pressure alert is worth sending at 03:00 — the
 * front is still coming — but not worth waking them for, so a push inside this
 * window goes out without a sound.
 */
export const QUIET_START_HOUR = 22;
export const QUIET_END_HOUR = 7;

/** The sun moves 15° of longitude an hour, which is where a zone would sit if civil time followed it. */
const DEGREES_PER_HOUR = 15;
const MS_PER_MINUTE = 60 * 1000;

/**
 * A rough UTC offset from longitude, 15° per hour, for a device that
 * registered before the app started sending its own offset. Wrong by up to two
 * hours where a country's civil time ignores the sun (China, Spain), which the
 * nine-hour window absorbs — and every device rewrites the real offset the next
 * time alerts are registered.
 */
export function offsetFromLongitude(lon: number): number {
  // `|| 0` normalises the -0 a longitude just west of Greenwich produces, which is harmless in arithmetic and reads as a bug in a log line.
  return Math.round(lon / DEGREES_PER_HOUR) * 60 || 0;
}

/** True when [now] falls in the user's local night, so the push must be silent. */
export function isQuietHour(now: Date, tzOffsetMinutes: number): boolean {
  // getUTCHours on the shifted instant IS the local hour: shifting by the offset
  // and then reading UTC is the one reading that never picks up the server's own zone.
  const local = new Date(now.getTime() + tzOffsetMinutes * MS_PER_MINUTE);
  const hour = local.getUTCHours();

  // The window crosses midnight, so it is a union rather than a range.
  return hour >= QUIET_START_HOUR || hour < QUIET_END_HOUR;
}
