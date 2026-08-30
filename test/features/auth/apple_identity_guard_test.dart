import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/auth/data/repositories/firebase_auth_repository.dart';

void main() {
  group('isSameAppleIdentity', () {
    test('the sheet answered for the linked identity', () {
      expect(
        FirebaseAuthRepository.isSameAppleIdentity(
          sheetUserIdentifier: '001234.abc.5678',
          linkedProviderUid: '001234.abc.5678',
        ),
        isTrue,
      );
    });

    test('another Apple ID is signed in on the device', () {
      // The bug this guards: revoking here took the app authorization away
      // from an Apple ID that had nothing to do with the account being
      // deleted.
      expect(
        FirebaseAuthRepository.isSameAppleIdentity(
          sheetUserIdentifier: '009999.zzz.0000',
          linkedProviderUid: '001234.abc.5678',
        ),
        isFalse,
      );
    });

    test('an unconfirmed identity is a no, not a maybe', () {
      expect(
        FirebaseAuthRepository.isSameAppleIdentity(
          sheetUserIdentifier: null,
          linkedProviderUid: '001234.abc.5678',
        ),
        isFalse,
      );
      expect(
        FirebaseAuthRepository.isSameAppleIdentity(
          sheetUserIdentifier: '',
          linkedProviderUid: '001234.abc.5678',
        ),
        isFalse,
      );
      // `UserInfo.uid` is nullable, so the account side can be missing too.
      expect(
        FirebaseAuthRepository.isSameAppleIdentity(
          sheetUserIdentifier: '001234.abc.5678',
          linkedProviderUid: null,
        ),
        isFalse,
      );
    });
  });
}
