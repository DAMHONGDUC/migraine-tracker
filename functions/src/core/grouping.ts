export interface AlertUser {
  uid: string;
  geohash5: string;
  fcmToken: string;
  thresholdHpa: number;
  /** Minutes east of UTC, so the run can tell whether it is the middle of this user's night. Resolved once when the run builds the user — the device's own offset, or the one its cell's longitude implies. */
  tzOffsetMinutes: number;
  history: { lastAlertAt?: Date; lastEventId?: string };
}

/** Hard rule 9: one forecast call per geohash cell, never per user. */
export function groupByGeohash(users: AlertUser[]): Map<string, AlertUser[]> {
  const cells = new Map<string, AlertUser[]>();
  for (const user of users) {
    const cell = cells.get(user.geohash5);
    if (cell) cell.push(user);
    else cells.set(user.geohash5, [user]);
  }
  return cells;
}
