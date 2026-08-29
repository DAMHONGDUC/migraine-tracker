/// The account's encryption key, held by the backend and fetched after sign-in.
abstract interface class SyncKeyRepository {
  /// The key for the signed-in user, minted by the backend on first use.
  Future<String> keyFor(String uid);

  /// Drops the cached key. Called on sign-out so the next account cannot reuse the previous one.
  void forget();
}
