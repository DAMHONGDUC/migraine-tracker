export interface AlertHistory {
  lastAlertAt?: Date;
  lastEventId?: string;
}

/**
 * The gap a user is guaranteed between two pushes. 8h is what caps them at
 * three a day: morning, afternoon and evening fronts are three different
 * warnings, and a wider window silently threw the later ones away.
 */
const MIN_PUSH_GAP_MS = 8 * 60 * 60 * 1000;

/** Dedupe: at most 3 pushes per user per day, {@link MIN_PUSH_GAP_MS} apart, and never twice for the same pressure event. */
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
