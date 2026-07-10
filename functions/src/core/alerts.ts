export interface AlertHistory {
  lastAlertAt?: Date;
  lastEventId?: string;
}

const DEDUPE_WINDOW_MS = 24 * 60 * 60 * 1000;

/**
 * Hard rule 9 dedupe: max 1 push per user per 24h per pressure event —
 * the same event never fires twice, and no user gets more than one push
 * in any 24h window regardless of how many fronts pass through.
 */
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
    now.getTime() - history.lastAlertAt.getTime() < DEDUPE_WINDOW_MS
  ) {
    return false;
  }
  return true;
}
