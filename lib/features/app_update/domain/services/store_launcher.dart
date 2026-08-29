/// Opens a store listing. Abstracted so the force-update flow is testable without the url_launcher plugin.
abstract interface class StoreLauncher {
  /// False when the link is malformed or no app can handle it. Never throws.
  Future<bool> open(String url);
}
