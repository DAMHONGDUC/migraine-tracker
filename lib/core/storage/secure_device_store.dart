import 'package:system_design/common.dart';

import 'secure_store.dart';

/// The Keychain as the store that outlives a delete — what makes a reinstall
/// tellable from a first install, and what the wipe empties.
///
/// An adapter rather than an `implements` on [SecureStore] itself, because the
/// two disagree about one method on purpose: [SdDeviceScopedStore.getKeys] is
/// async, while `SecureStore.getKeys` reads the startup snapshot synchronously
/// and is called from `build` (`PrefsSyncCursorStore` walks it). The interface
/// is satisfied here, at the one call site that can await.
///
/// **The on-device database is deliberately not part of the wipe.** The reason
/// is on `AppFreshInstall`.
final class SecureDeviceStore implements SdDeviceScopedStore {
  const SecureDeviceStore(this._store);

  final SecureStore _store;

  @override
  Future<Iterable<String>> getKeys() async => _store.getKeys();

  @override
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  @override
  Future<void> setInt(String key, int value) => _store.setInt(key, value);

  @override
  Future<void> setDouble(String key, double value) =>
      _store.setDouble(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);

  /// The whole Keychain — onboarding, thresholds, sync cursors.
  @override
  Future<void> deleteAll() => _store.deleteAll();
}
