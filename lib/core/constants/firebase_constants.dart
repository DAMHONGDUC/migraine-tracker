/// Where the backend lives.
final class FirebaseConstants {
  const FirebaseConstants._();

  /// Must match the `REGION` in `functions/src/index.ts`. The SDK default is us-central1, which would miss every function this project deploys.
  static const String functionsRegion = 'europe-west1';
}
