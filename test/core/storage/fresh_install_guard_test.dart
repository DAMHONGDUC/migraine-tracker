import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/storage/fresh_install_guard.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// iOS keeps the Keychain across a delete but not `shared_preferences`, so a seeded store with empty prefs IS the reinstall this guard exists for.
  Future<(SharedPreferences, SecureStore)> setUpStorage({
    Map<String, Object> prefs = const <String, Object>{},
    Map<String, String> keychain = const <String, String>{},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(keychain));

    return (await SharedPreferences.getInstance(), await SecureStore.open());
  }

  test(
    'a reinstall clears the Keychain and signs the old session out',
    () async {
      final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
        keychain: <String, String>{'app_locale': 'vi'},
      );
      int signOuts = 0;

      await FreshInstallGuard.run(prefs, store, () async => signOuts++);

      expect(store.getString('app_locale'), isNull);
      expect(signOuts, 1);
      expect(prefs.getBool(FreshInstallGuard.installMarkerKey), isTrue);
    },
  );

  test('an update carries the old settings over and still signs out', () async {
    final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
      prefs: <String, Object>{
        'onboarding_completed': true,
        'alert_threshold': 7.0,
      },
    );
    int signOuts = 0;

    await FreshInstallGuard.run(prefs, store, () async => signOuts++);

    expect(store.getBool('onboarding_completed'), isTrue);
    expect(store.getDouble('alert_threshold'), 7);
    // The session goes on every first launch: guessing wrong about which kind it is would leave the user signed into an install they never signed into.
    expect(signOuts, 1);
    // One owner per value: the copies left in shared_preferences go once they are carried.
    expect(prefs.getKeys(), <String>{FreshInstallGuard.installMarkerKey});
  });

  test('a later launch of the same install touches nothing', () async {
    final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
      prefs: <String, Object>{FreshInstallGuard.installMarkerKey: true},
      keychain: <String, String>{'app_locale': 'vi'},
    );
    int signOuts = 0;

    await FreshInstallGuard.run(prefs, store, () async => signOuts++);

    expect(store.getString('app_locale'), 'vi');
    expect(signOuts, isZero);
  });
}
