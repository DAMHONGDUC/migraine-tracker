/// Opens an external web link. Abstracted for the same reason
/// `StoreLauncher` and `MailLauncher` are: so the screen that uses it is
/// testable without the url_launcher plugin.
abstract interface class LinkLauncher {
  /// False when the link is malformed or nothing can handle it. Never throws —
  /// a legal link that fails to open must not take the paywall down with it.
  Future<bool> open(String url);
}
