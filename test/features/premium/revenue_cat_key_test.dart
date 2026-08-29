import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/premium/data/datasources/revenue_cat_client.dart';

/// A wrong-platform key does not throw in Dart — RevenueCat's native SDK answers it with `fatalError` and kills the process, in release builds only.
void main() {
  group('on Apple', () {
    bool usable(String key) =>
        RevenueCatClient.isUsableKey(key, forApple: true);

    test('an Apple key is accepted', () {
      expect(usable('appl_aBcDeFgH12345'), isTrue);
    });

    test('an Android key is refused', () {
      // The likeliest paste error, and one the SDK will not survive.
      expect(usable('goog_aBcDeFgH12345'), isFalse);
    });

    test('a half-filled template is refused', () {
      // What actually crashed TestFlight.
      expect(usable('test_key'), isFalse);
      expect(usable('strp_something'), isFalse);
      expect(usable('REPLACE_ME'), isFalse);
    });

    test('an empty key is refused', () {
      expect(usable(''), isFalse);
    });

    test('a legacy unprefixed key is allowed through', () {
      // RevenueCat only warns about these, so refusing them would break a working setup for the sake of a crash that cannot happen.
      expect(usable('aBcDeFgH12345'), isTrue);
    });
  });

  group('on Android', () {
    bool usable(String key) =>
        RevenueCatClient.isUsableKey(key, forApple: false);

    test('the platforms are mirrored', () {
      expect(usable('goog_aBcDeFgH12345'), isTrue);
      expect(usable('appl_aBcDeFgH12345'), isFalse);
      expect(usable('test_key'), isFalse);
    });
  });
}
