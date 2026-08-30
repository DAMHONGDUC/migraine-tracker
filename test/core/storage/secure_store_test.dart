import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SecureStore> openWith([
    Map<String, String> seed = const <String, String>{},
  ]) async {
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.of(seed));

    return SecureStore.open();
  }

  test('reads what the Keychain already held', () async {
    final SecureStore store = await openWith(<String, String>{
      'app_locale': 'vi',
      'alerts_enabled': 'true',
      'alert_threshold': '7.0',
      'review_prompt_count': '2',
    });

    expect(store.getString('app_locale'), 'vi');
    expect(store.getBool('alerts_enabled'), isTrue);
    expect(store.getDouble('alert_threshold'), 7);
    expect(store.getInt('review_prompt_count'), 2);
  });

  test('a written value reads back through the same store', () async {
    final SecureStore store = await openWith();

    await store.setBool('alerts_enabled', false);
    await store.setDouble('alert_threshold', 3.5);

    expect(store.getBool('alerts_enabled'), isFalse);
    expect(store.getDouble('alert_threshold'), 3.5);
  });

  test('an absent key is null rather than a default', () async {
    final SecureStore store = await openWith();

    expect(store.getBool('alerts_enabled'), isNull);
    expect(store.getInt('review_prompt_count'), isNull);
    expect(store.getString('app_locale'), isNull);
  });

  test('remove drops one key, deleteAll drops every key', () async {
    final SecureStore store = await openWith(<String, String>{
      'app_locale': 'vi',
      'alerts_enabled': 'true',
    });

    await store.remove('app_locale');

    expect(store.getString('app_locale'), isNull);
    expect(store.getBool('alerts_enabled'), isTrue);

    await store.deleteAll();

    expect(store.getKeys(), isEmpty);
  });

  /// The Keychain outlives the app, so a reopened store must see what the last one wrote — this is the survival the fresh-install guard exists to undo.
  test('what one store wrote, the next one opens with', () async {
    final SecureStore first = await openWith();

    await first.setString('app_locale', 'ja');

    final SecureStore second = await SecureStore.open();

    expect(second.getString('app_locale'), 'ja');
  });
}
