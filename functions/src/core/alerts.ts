export interface AlertHistory {
  lastAlertAt?: Date;
  lastEventId?: string;
}

/**
 * The gap a user is guaranteed between two pushes. 12h is what caps them at
 * two a day: a front that arrives in the morning and a second one that evening
 * are different warnings, and 24h silently threw the second away.
 */
const MIN_PUSH_GAP_MS = 12 * 60 * 60 * 1000;

/** Dedupe: at most 2 pushes per user per day, {@link MIN_PUSH_GAP_MS} apart, and never twice for the same pressure event. */
export function shouldAlert(args: {
  dropHpa: number;
  thresholdHpa: number;
  eventId: string;
  history: AlertHistory;
  now: Date;
}): boolean {
  const { dropHpa, thresholdHpa, eventId, history, now } = args;
  if (dropHpa < thresholdHpa) return false;
  if (history.lastEventId === eventId) return false;
  if (
    history.lastAlertAt !== undefined &&
    now.getTime() - history.lastAlertAt.getTime() < MIN_PUSH_GAP_MS
  ) {
    return false;
  }
  return true;
}
