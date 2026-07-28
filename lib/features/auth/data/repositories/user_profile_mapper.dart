import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

/// The account half of the `users/{uid}` document, in one place.
///
/// The same document also carries the alert-registration keys (`geohash5`,
/// `fcmToken`, `alertThreshold`, `tz`) and the webhook-owned `premium` flag
/// — this mapper reads and writes ONLY the account keys below, so the two
/// concerns can never clobber each other.
///
/// ```
/// users/{uid}
///   displayName: string
///   email:       string
///   photoUrl:    string
///   createdAt:   Timestamp (server, written once)
///   updatedAt:   Timestamp (server)
/// ```
abstract final class UserProfileMapper {
  static const String displayNameField = 'displayName';
  static const String emailField = 'email';
  static const String photoUrlField = 'photoUrl';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  static UserProfile fromMap(String uid, Map<String, Object?> data) =>
      UserProfile(
        uid: uid,
        displayName: _stringFrom(data[displayNameField]),
        email: _stringFrom(data[emailField]),
        photoUrl: _stringFrom(data[photoUrlField]),
        createdAt: _dateFrom(data[createdAtField]),
        updatedAt: _dateFrom(data[updatedAtField]),
      );

  /// Only the keys the provider actually gave us: a merge write with a null
  /// would erase a good value (Apple withholds the email after the first
  /// sign-in) and `displayName` is the user's to own once they edit it.
  static Map<String, Object?> toWrite({
    String? displayName,
    String? email,
    String? photoUrl,
    bool includeDisplayName = true,
  }) => <String, Object?>{
    if (includeDisplayName && displayName != null && displayName.isNotEmpty)
      displayNameField: displayName,
    if (email != null && email.isNotEmpty) emailField: email,
    if (photoUrl != null && photoUrl.isNotEmpty) photoUrlField: photoUrl,
    updatedAtField: FieldValue.serverTimestamp(),
  };

  /// Empty strings are treated as absent — a cleared field is not a name.
  static String? _stringFrom(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static DateTime? _dateFrom(Object? value) => switch (value) {
    final Timestamp timestamp => timestamp.toDate().toUtc(),
    final DateTime date => date.toUtc(),
    _ => null,
  };
}
