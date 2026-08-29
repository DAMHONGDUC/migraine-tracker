/** The spellings a `users.email` field may hold for the build's PREMIUM_EMAIL account, ready for an `in` query. Empty when the build carries no such address. */
export function premiumEmailMatches(configured: string): string[] {
  const trimmed = configured.trim();

  if (trimmed.length === 0) return [];

  // Firestore `==` is case-sensitive and the provider writes the address as it has it, so both spellings are asked for — the app matches case-insensitively.
  const lower = trimmed.toLowerCase();

  return lower === trimmed ? [trimmed] : [trimmed, lower];
}
