/// Opens the device's mail client pre-addressed to support. Abstracted so
/// the contact screen is testable without the url_launcher plugin.
abstract interface class MailLauncher {
  /// False when no mail app can handle the link. Never throws.
  Future<bool> open({required String to, required String subject, String? body});
}
