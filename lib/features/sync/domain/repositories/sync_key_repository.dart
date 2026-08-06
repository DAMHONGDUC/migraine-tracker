/// The account's encryption key, held by the backend and fetched after
/// sign-in.
abstract interface class SyncKeyRepository {
  /// The key for the signed-in user, minted by the backend on first use.
  ///
  /// Cached in memory for the session only. It is deliberately never written
  /// to disk: sync needs the network anyway, so re-fetching once per launch
  /// costs one call and avoids a second secret sitting on the device.
  Future<String> keyFor(String uid);

  /// Drops the cached key. Called on sign-out so the next account cannot
  /// reuse the previous one.
  void forget();
}
