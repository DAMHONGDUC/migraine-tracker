/** Maps a RevenueCat webhook event type to the user's premium flag. */
export function premiumFromEvent(eventType: string): boolean | null {
  switch (eventType) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "NON_RENEWING_PURCHASE":
      return true;
    case "EXPIRATION":
      return false;
    default:
      return null;
  }
}
