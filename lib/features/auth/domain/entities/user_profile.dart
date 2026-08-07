import 'package:meta/meta.dart';

/// The signed-in user's account record, as stored in `users/{uid}`.
///
/// Account data only — name, email, avatar, when the account started.
/// NEVER health data: attacks live on-device and, for signed-in users, as
/// encrypted payloads in the top-level `attacks` collection (hard rule 1).
@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;

  /// What the account screen shows and lets the user edit. Null until the
  /// provider gave us one (Apple often doesn't) or the user typed one.
  final String? displayName;

  final String? email;
  final String? photoUrl;

  /// Server time of the first write — "member since" on the account screen.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile copyWith({String? displayName}) => UserProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    email: email,
    photoUrl: photoUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
