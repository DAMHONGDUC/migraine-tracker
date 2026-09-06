import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

/// `shared_preferences` as the store iOS deletes with the app — where
/// [SdFreshInstall] keeps its stamp, and the only thing this app writes there.
///
/// A wrapper rather than an `implements` on the plugin's own class:
/// `SharedPreferences` is final, and this is the only place in the app that
/// reads it at all — everything else goes through `SecureStore`.
///
/// Every method is async because the interface is: one host awaits the plugin
/// on each call, this one reads an instance loaded at startup.
final class PrefsInstallStore implements SdInstallScopedStore {
  const PrefsInstallStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Iterable<String>> getKeys() async => _prefs.getKeys();

  @override
  Future<Object?> get(String key) async => _prefs.get(key);

  /// Reads through [get] rather than `getString`: the plugin's typed getter
  /// casts, and the one legacy key an install can still be carrying —
  /// `is_installed` — is a `bool`. A stamp that threw would be read as absent
  /// on every launch.
  @override
  Future<String?> getString(String key) async {
    final Object? value = _prefs.get(key);

    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}
