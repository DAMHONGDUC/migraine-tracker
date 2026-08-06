/// Remembers how far the last pull got, per account.
///
/// Scoped by uid on purpose: signing into a different account must start from
/// nothing rather than inherit the previous one's position and skip its
/// history.
abstract interface class SyncCursorStore {
  Future<DateTime?> lastPulledAt(String uid);

  Future<void> save(String uid, DateTime at);

  /// Forgets every account's position (sign-out, GDPR wipe).
  Future<void> clear();
}
