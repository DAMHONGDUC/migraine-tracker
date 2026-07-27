import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/auth/data/repositories/user_profile_mapper.dart';
import 'package:migraine_tracker/features/auth/domain/entities/user_profile.dart';

void main() {
  group('fromMap', () {
    test('reads the account fields', () {
      final UserProfile profile = UserProfileMapper.fromMap(
        'uid-1',
        <String, Object?>{
          'displayName': 'Duc',
          'email': 'duc@example.com',
          'photoUrl': 'https://example.com/a.png',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 20)),
          // The alert-registration keys share the document and must be
          // ignored, not mistaken for account data.
          'geohash5': 'w3gvk',
          'premium': true,
        },
      );

      expect(profile.uid, 'uid-1');
      expect(profile.displayName, 'Duc');
      expect(profile.email, 'duc@example.com');
      expect(profile.createdAt, DateTime.utc(2026, 7, 20));
    });

    test('an empty or blank name is no name', () {
      final UserProfile profile = UserProfileMapper.fromMap(
        'uid-1',
        <String, Object?>{'displayName': '   ', 'email': ''},
      );

      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
    });

    test('a document with only alert keys yields an empty profile', () {
      final UserProfile profile = UserProfileMapper.fromMap(
        'uid-1',
        <String, Object?>{'geohash5': 'w3gvk', 'fcmToken': 'token'},
      );

      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
      expect(profile.createdAt, isNull);
    });
  });

  group('toWrite', () {
    test('omits what the provider did not give us', () {
      final Map<String, Object?> write = UserProfileMapper.toWrite(
        displayName: 'Duc',
        email: null,
        photoUrl: '',
      );

      expect(write.containsKey('displayName'), isTrue);
      // A null email must not erase the one Apple sent on first sign-in.
      expect(write.containsKey('email'), isFalse);
      expect(write.containsKey('photoUrl'), isFalse);
      expect(write.containsKey('updatedAt'), isTrue);
    });

    test('leaves a name the user typed alone', () {
      final Map<String, Object?> write = UserProfileMapper.toWrite(
        displayName: 'From Google',
        includeDisplayName: false,
      );

      expect(write.containsKey('displayName'), isFalse);
    });

    test('never writes the webhook-owned premium flag', () {
      expect(
        UserProfileMapper.toWrite(displayName: 'Duc').containsKey('premium'),
        isFalse,
      );
    });
  });
}
