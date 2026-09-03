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

/**
 * How close the fall has to be before the second, imminent push goes out.
 *
 * One hour, which is what makes it act on: "a front is coming tomorrow" is a
 * plan, "it starts within the hour" is a dose.
 */
const ONSET_WINDOW_MS = 60 * 60 * 1000;

/** Which of the two pushes a user is owed for this event, or null for neither. */
export type AlertStage = "ahead" | "onset";

/** The event id a stage is deduped under. The onset push carries its own, so it is not swallowed as a repeat of the heads-up. */
export function stageEventId(eventId: string, stage: AlertStage): string {
  return stage === "onset" ? `${eventId}:onset` : eventId;
}

/**
 * Dedupe: at most 3 heads-up pushes per user per day, {@link MIN_PUSH_GAP_MS}
 * apart, never twice for the same pressure event — plus one onset push per
 * event, which the gap deliberately does not hold back.
 */
export function alertStage(args: {
  dropHpa: number;
  thresholdHpa: number;
  eventId: string;
  startsAt: Date;
  history: AlertHistory;
  now: Date;
}): AlertStage | null {
  const { dropHpa, thresholdHpa, eventId, startsAt, history, now } = args;

  if (dropHpa < thresholdHpa) return null;

  const untilStart = startsAt.getTime() - now.getTime();
  const isImminent = untilStart <= ONSET_WINDOW_MS;

  if (isImminent) {
    // Once per event, and the 8h gap does not apply: this is the push the heads-up was preparing the user for, and holding it back would deliver the warning after the front.
    return history.lastEventId === stageEventId(eventId, "onset")
      ? null
      : "onset";
  }
  if (history.lastEventId === eventId) return null;
  if (
    history.lastAlertAt !== undefined &&
    now.getTime() - history.lastAlertAt.getTime() < MIN_PUSH_GAP_MS
  ) {
    return null;
  }
  return "ahead";
}

/** Whether the heads-up push is owed. Kept as the narrow question the run used to ask, and now answered by {@link alertStage}. */
export function shouldAlert(args: {
  dropHpa: number;
  thresholdHpa: number;
  eventId: string;
  history: AlertHistory;
  now: Date;
}): boolean {
  return (
    alertStage({
      ...args,
      // No onset time means the caller is asking the old question: treat the fall as far off so only the heads-up rules apply.
      startsAt: new Date(args.now.getTime() + ONSET_WINDOW_MS + 1),
    }) === "ahead"
  );
}
