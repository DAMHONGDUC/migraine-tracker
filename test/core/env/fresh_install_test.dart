import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/env/app_fresh_install.dart';
import 'package:migraine_tracker/core/storage/prefs_install_store.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

/// The key the old guard wrote, and the only thing an install shipped before
/// the stamp has in `shared_preferences`.
const String _legacyMarker = 'is_installed';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A test build has no Firebase config, so `isBackendReady` is false and
  /// both vendor steps skip themselves. What is left to assert is the store
  /// half — which is the half this app gets to decide. `AppEnv.flavor` is
  /// `dev` here, so that is the stamp every run below writes.
  Future<(ProviderContainer, SharedPreferences, SecureStore)> setUpDevice({
    Map<String, Object> prefs = const <String, Object>{},
    Map<String, String> keychain = const <String, String>{},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(keychain));

    final SecureStore store = await SecureStore.open();
    final ProviderContainer container = ProviderContainer(
      overrides: [secureStoreProvider.overrideWithValue(store)],
    );

    addTearDown(container.dispose);

    return (container, await SharedPreferences.getInstance(), store);
  }

  group('AppFreshInstall', () {
    /// The row that costs real users if it is wrong: everyone already on the
    /// app carries the old marker and no stamp, and a wipe here would sign
    /// every one of them out on the update that ships this.
    test('an install carrying the old marker reads as an update', () async {
      final (
        ProviderContainer container,
        SharedPreferences prefs,
        SecureStore store,
      ) = await setUpDevice(
        prefs: <String, Object>{_legacyMarker: true},
        keychain: <String, String>{
          PrefsKeyConstant.onboardingCompleted: 'true',
          PrefsKeyConstant.alertThreshold: '7.0',
        },
      );

      expect(await AppFreshInstall.run(container, prefs), SdFreshInstallOutcome.update);

      expect(store.getBool(PrefsKeyConstant.onboardingCompleted), isTrue);
      expect(store.getDouble(PrefsKeyConstant.alertThreshold), 7);
      // One owner per value: the marker moves into the Keychain with the rest
      // of the legacy keys, so the stamp is all that is left behind.
      expect(prefs.getKeys(), <String>{PrefsKeyConstant.lastEnv});
      expect(prefs.getString(PrefsKeyConstant.lastEnv), 'dev');
    });

    test('a second launch of the same build does nothing', () async {
      final (
        ProviderContainer container,
        SharedPreferences prefs,
        SecureStore store,
      ) = await setUpDevice(
        prefs: <String, Object>{PrefsKeyConstant.lastEnv: 'dev'},
        keychain: <String, String>{PrefsKeyConstant.onboardingCompleted: 'true'},
      );

      expect(
        await AppFreshInstall.run(container, prefs),
        SdFreshInstallOutcome.normalLaunch,
      );

      expect(store.getBool(PrefsKeyConstant.onboardingCompleted), isTrue);
    });

    /// Install, sign in, delete, install again. Only the Keychain survives
    /// that, and it must not be what carries the session back.
    test('the Keychain does not survive a delete and reinstall', () async {
      final (
        ProviderContainer container,
        SharedPreferences prefs,
        SecureStore store,
      ) = await setUpDevice(
        keychain: <String, String>{
          PrefsKeyConstant.onboardingCompleted: 'true',
          'app_locale': 'vi',
        },
      );

      expect(
        await AppFreshInstall.run(container, prefs),
        SdFreshInstallOutcome.reinstall,
      );

      expect(store.getKeys(), isEmpty);
      expect(prefs.getString(PrefsKeyConstant.lastEnv), 'dev');
    });

    test('a prod install under a dev binary is wiped', () async {
      final (
        ProviderContainer container,
        SharedPreferences prefs,
        SecureStore store,
      ) = await setUpDevice(
        prefs: <String, Object>{PrefsKeyConstant.lastEnv: 'prod'},
        keychain: <String, String>{PrefsKeyConstant.onboardingCompleted: 'true'},
      );

      expect(
        await AppFreshInstall.run(container, prefs),
        SdFreshInstallOutcome.environmentChanged,
      );

      expect(store.getKeys(), isEmpty);
      // The stamp is written after the wipe cleared the store it lives in.
      expect(prefs.getKeys(), <String>{PrefsKeyConstant.lastEnv});
      expect(prefs.getString(PrefsKeyConstant.lastEnv), 'dev');
    });

    test('nothing on the device is a first install, and wipes nothing', () async {
      final (
        ProviderContainer container,
        SharedPreferences prefs,
        SecureStore store,
      ) = await setUpDevice();

      expect(
        await AppFreshInstall.run(container, prefs),
        SdFreshInstallOutcome.firstInstall,
      );

      expect(store.getKeys(), isEmpty);
      expect(prefs.getString(PrefsKeyConstant.lastEnv), 'dev');
    });
  });

  group('PrefsInstallStore', () {
    /// The plugin's own `getString` casts, and the legacy marker is a `bool`.
    /// A throw here would read as "no stamp" on every launch, forever.
    test('a non-string value under a key reads as absent', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        _legacyMarker: true,
      });

      final PrefsInstallStore store = PrefsInstallStore(
        await SharedPreferences.getInstance(),
      );

      expect(await store.getString(_legacyMarker), isNull);
      expect(await store.get(_legacyMarker), isTrue);
    });
  });
}
