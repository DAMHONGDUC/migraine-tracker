import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';

/// Overridden in `main()` with what `AppBootstrap.init` loaded, and in tests with a seeded one.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw UnimplementedError(
    'secureStoreProvider must be overridden at app start',
  ),
);

/// Every local key-value the app keeps, in the Keychain rather than in `shared_preferences` (owner's rule) — see `docs/rules/PRIVACY_AND_SECURITY.md`.
///
/// Reads are synchronous off a snapshot taken once at startup, because controllers read them inside `build`; a write goes to the Keychain first and updates the snapshot after, so a failed write never leaves the app showing a value it did not keep.
class SecureStore {
  SecureStore(this._storage, this._values);

  /// `first_unlock_this_device`: readable by anything running after the first unlock of the day, and never restored onto a second device from an iCloud backup — this is health-adjacent state, not something to hand to another handset.
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  /// The startup snapshot. Owned here, mutated only by the writers below.
  final Map<String, String> _values;

  /// Reads the whole Keychain once. A failure is logged and answered with an empty store rather than a dead app — every value it holds has a default at its call site.
  static Future<SecureStore> open() async {
    const FlutterSecureStorage storage = FlutterSecureStorage(
      iOptions: _iosOptions,
    );

    try {
      final Map<String, String> values = await storage.readAll();

      SdLogger.info(LogTagConstant.storage, 'Secure store loaded', {
        'keys': values.length,
      });

      return SecureStore(storage, Map<String, String>.of(values));
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.storage,
        'Secure store read failed, starting empty',
        error: error,
        stackTrace: stackTrace,
      );

      return SecureStore(storage, <String, String>{});
    }
  }

  String? getString(String key) => _values[key];

  /// Anything that is not the string `true` reads as false, so a half-written value is off rather than surprising.
  bool? getBool(String key) {
    final String? raw = _values[key];

    return raw == null ? null : raw == 'true';
  }

  int? getInt(String key) => int.tryParse(_values[key] ?? '');

  double? getDouble(String key) => double.tryParse(_values[key] ?? '');

  /// A copy: the sync cursor store walks this while removing from it.
  Iterable<String> getKeys() => _values.keys.toList();

  Future<void> setString(String key, String value) => _write(key, value);

  Future<void> setBool(String key, bool value) => _write(key, '$value');

  Future<void> setInt(String key, int value) => _write(key, '$value');

  Future<void> setDouble(String key, double value) => _write(key, '$value');

  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
      _values.remove(key);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.storage,
        'Secure store delete failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'key': key},
      );
      rethrow;
    }
  }

  /// Everything, in one call — what [FreshInstallGuard] uses to make a reinstall look like a first install.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _values.clear();
      SdLogger.info(LogTagConstant.storage, 'Secure store cleared');
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.storage,
        'Secure store clear failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _values[key] = value;
    } catch (error, stackTrace) {
      // The value is never logged: this store is where the private things live.
      SdLogger.error(
        LogTagConstant.storage,
        'Secure store write failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'key': key},
      );
      rethrow;
    }
  }
}
