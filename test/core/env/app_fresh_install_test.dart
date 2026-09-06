import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/prefs_key_constant.dart';
import 'package:migraine_tracker/core/env/app_fresh_install.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';
import 'package:system_design/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A test build has no Firebase config, so both wipe steps skip themselves and what is left to assert is the store half — which is the half this app gets to decide.
  Future<(SdFreshInstallPolicy, SharedPreferences, SecureStore)> setUpPolicy({
    Map<String, String> keychain = const <String, String>{},
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SdReinstallGuard.isInstalledKey: true,
    });
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(keychain));

    final SecureStore store = await SecureStore.open();
    final ProviderContainer container = ProviderContainer(
      overrides: [secureStoreProvider.overrideWithValue(store)],
    );

    addTearDown(container.dispose);

    return (
      container.read(appFreshInstallPolicyProvider)!,
      await SharedPreferences.getInstance(),
      store,
    );
  }

  group('AppFreshInstall', () {
    test('reads nothing on a device that has never recorded a flavour', () async {
      final (SdFreshInstallPolicy policy, _, _) = await setUpPolicy();

      // Null is what stops the guard wiping a real first install.
      expect(await policy.readLastEnv(), isNull);
    });

    test('records the flavour in the Keychain and reads it back', () async {
      final (SdFreshInstallPolicy policy, _, SecureStore store) =
          await setUpPolicy();

      await policy.writeEnv('dev');

      expect(await policy.readLastEnv(), 'dev');
      expect(store.getString(PrefsKeyConstant.lastEnv), 'dev');
    });

    test('leaves `shared_preferences` alone, so a reinstall still reads as one', () async {
      final (SdFreshInstallPolicy policy, SharedPreferences prefs, _) =
          await setUpPolicy();

      await policy.writeEnv('dev');
      await policy.wipe('prod', 'dev');

      // A key of ours beside the marker is what `SdReinstallGuard` reads as an
      // upgrade — it would keep the session across a delete and reinstall.
      expect(prefs.getKeys(), <String>{SdReinstallGuard.isInstalledKey});
    });

    test('wipes the Keychain, record included', () async {
      final (SdFreshInstallPolicy policy, _, SecureStore store) =
          await setUpPolicy(
            keychain: <String, String>{
              PrefsKeyConstant.lastEnv: 'dev',
              PrefsKeyConstant.onboardingCompleted: 'true',
              PrefsKeyConstant.alertThreshold: '7.0',
            },
          );

      await policy.wipe('dev', 'prod');

      expect(store.getKeys(), isEmpty);
    });
  });
}
