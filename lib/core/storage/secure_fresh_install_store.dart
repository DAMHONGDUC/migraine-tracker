import 'package:system_design/common.dart';

import 'secure_store.dart';

/// The Keychain as the store the flavour-change wipe reads, records and clears.
///
/// **Deliberately not `shared_preferences`.** Every key-value this app writes
/// lives in `SecureStore` (`docs/rules/PRIVACY_AND_SECURITY.md`), so a wipe
/// aimed at prefs would clear almost nothing — and the one prefs key that does
/// exist, `SdReinstallGuard.isInstalledKey`, is the marker that tells a
/// reinstall from an update. Writing the environment record beside it would
/// read as a legacy key on the next delete-and-reinstall, and that guard would
/// call it an update and leave the old session signed in.
final class SecureFreshInstallStore implements SdFreshInstallStore {
  const SecureFreshInstallStore(this._store);

  final SecureStore _store;

  /// Reads the startup snapshot, which is taken before this ever runs.
  @override
  Future<String?> readString(String key) async => _store.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _store.setString(key, value);

  /// The whole Keychain — onboarding, thresholds, sync cursors, the record
  /// itself. The on-device database is deliberately not part of it; the reason
  /// is on `AppFreshInstall`.
  @override
  Future<void> clear() => _store.deleteAll();
}
