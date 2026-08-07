/// Where the backend lives. Shared because more than one feature calls into
/// it — sync fetches its key, auth deletes the account — and a callable
/// looked up in the wrong region simply is not found.
final class FirebaseConstants {
  const FirebaseConstants._();

  /// Must match the `REGION` in `functions/src/index.ts`. The SDK default is
  /// us-central1, which would miss every function this project deploys.
  static const String functionsRegion = 'europe-west1';
}
