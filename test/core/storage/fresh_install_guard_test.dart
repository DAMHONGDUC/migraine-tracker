import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/storage/fresh_install_guard.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for `FirebaseAuth.instance.signOut`, and records the order it was called in relative to the marker.
class RecordingSignOut {
  int calls = 0;
  bool fails = false;

  Future<void> call() async {
    calls++;
    if (fails) throw StateError('sign-out failed');
  }
}

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

  group('reinstall', () {
    test('clears the Keychain and signs the old session out', () async {
      final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
        keychain: <String, String>{'app_locale': 'vi'},
      );
      final RecordingSignOut signOut = RecordingSignOut();

      await FreshInstallGuard.run(prefs, store, signOut.call);

      expect(store.getString('app_locale'), isNull);
      expect(signOut.calls, 1);
      expect(prefs.getBool(FreshInstallGuard.isInstalledKey), isTrue);
    });

    /// The whole reason the guard exists: install, sign in, delete, install again. Only the Keychain survives that, and it must not be what carries the session back.
    test('the session does not survive a delete and reinstall', () async {
      final (SharedPreferences first, SecureStore firstStore) =
          await setUpStorage();
      final RecordingSignOut signOut = RecordingSignOut();

      // First install, then the user signs in and the app writes settings.
      await FreshInstallGuard.run(first, firstStore, signOut.call);
      await firstStore.setBool('onboarding_completed', true);

      // The delete takes shared_preferences and the database; the Keychain stays.
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final SharedPreferences second = await SharedPreferences.getInstance();
      final SecureStore secondStore = await SecureStore.open();

      expect(
        secondStore.getBool('onboarding_completed'),
        isTrue,
        reason: 'the Keychain is expected to survive — that is the problem',
      );

      await FreshInstallGuard.run(second, secondStore, signOut.call);

      expect(signOut.calls, 2);
      expect(secondStore.getKeys(), isEmpty);
    });

    test(
      'a failed sign-out still clears the Keychain and marks the install',
      () async {
        final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
          keychain: <String, String>{'app_locale': 'vi'},
        );
        final RecordingSignOut signOut = RecordingSignOut()..fails = true;

        await FreshInstallGuard.run(prefs, store, signOut.call);

        expect(signOut.calls, 1);
        expect(store.getKeys(), isEmpty);
        expect(prefs.getBool(FreshInstallGuard.isInstalledKey), isTrue);
      },
    );
  });

  group('update', () {
    test('carries the old settings over and keeps the session', () async {
      final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
        prefs: <String, Object>{
          'onboarding_completed': true,
          'alert_threshold': 7.0,
          'app_locale': 'vi',
          'review_prompt_count': 2,
        },
      );
      final RecordingSignOut signOut = RecordingSignOut();

      await FreshInstallGuard.run(prefs, store, signOut.call);

      expect(store.getBool('onboarding_completed'), isTrue);
      expect(store.getDouble('alert_threshold'), 7);
      expect(store.getString('app_locale'), 'vi');
      expect(store.getInt('review_prompt_count'), 2);
      // Nothing was deleted on an update, so there is nothing to make fresh.
      expect(signOut.calls, isZero);
      // One owner per value: the copies left in shared_preferences go once they are carried.
      expect(prefs.getKeys(), <String>{FreshInstallGuard.isInstalledKey});
    });
  });

  group('same install', () {
    test('a later launch touches nothing', () async {
      final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
        prefs: <String, Object>{FreshInstallGuard.isInstalledKey: true},
        keychain: <String, String>{'app_locale': 'vi'},
      );
      final RecordingSignOut signOut = RecordingSignOut();

      await FreshInstallGuard.run(prefs, store, signOut.call);

      expect(store.getString('app_locale'), 'vi');
      expect(signOut.calls, isZero);
    });

    /// The marker is written by the guard itself, so counting it as a legacy value would make every first launch look like an update.
    test('the marker alone is not read as an update', () async {
      final (SharedPreferences prefs, SecureStore store) = await setUpStorage(
        prefs: <String, Object>{FreshInstallGuard.isInstalledKey: false},
      );
      final RecordingSignOut signOut = RecordingSignOut();

      await FreshInstallGuard.run(prefs, store, signOut.call);

      expect(signOut.calls, 1);
    });
  });
}
