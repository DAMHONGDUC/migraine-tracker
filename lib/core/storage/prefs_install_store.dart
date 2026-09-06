import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

/// `shared_preferences` as the store iOS deletes with the app, for [SdReinstallGuard].
///
/// A wrapper rather than an `implements` on the plugin's own class: `SharedPreferences` is final, and this is the only place in the app that reads it at all — everything else goes through `SecureStore`.
final class PrefsInstallStore implements SdInstallScopedStore {
  const PrefsInstallStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Iterable<String> getKeys() => _prefs.getKeys();

  @override
  Object? get(String key) => _prefs.get(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
