import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'user_profile_mapper.dart';

/// The account document for a signed-in user, in the same `users/{uid}` doc the alert registration already writes (merge writes, disjoint keys.
class FirestoreUserProfileRepository implements UserProfileRepository {
  const FirestoreUserProfileRepository(this._firestore);

  static const String collectionPath = 'users';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(collectionPath).doc(uid);

  @override
  Stream<UserProfile?> watch(String uid) =>
      _doc(uid).snapshots().map((DocumentSnapshot<Map<String, dynamic>> snap) {
        final Map<String, dynamic>? data = snap.data();

        if (!snap.exists || data == null) return null;
        return UserProfileMapper.fromMap(uid, data);
      });

  /// One read before the write, to answer two questions the write itself cannot.
  @override
  Future<bool> upsertFromAccount(AuthUser user) async {
    final DocumentSnapshot<Map<String, dynamic>> existing = await _doc(
      user.uid,
    ).get();
    final bool hasOwnName =
        UserProfileMapper.fromMap(
          user.uid,
          existing.data() ?? <String, Object?>{},
        ).displayName !=
        null;
    final Map<String, Object?> write = UserProfileMapper.toWrite(
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      includeDisplayName: !hasOwnName,
    );

    if (!existing.exists) {
      write[UserProfileMapper.createdAtField] = FieldValue.serverTimestamp();
    }

    // Field names, never their values: this document holds the user's name, email and photo URL, and none of that belongs in a console.
    final Map<String, Object?> what = <String, Object?>{
      'uid': user.uid,
      'isNew': !existing.exists,
      'fields': write.keys.toList(),
    };

    SdLogger.action(LogTagConstant.profile, 'Write profile', what);
    try {
      await _doc(user.uid).set(write, SetOptions(merge: true));
      SdLogger.info(LogTagConstant.profile, 'Profile written', what);

      return !existing.exists;
    } on FirebaseException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.profile,
        'Write profile failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{...what, 'code': error.code},
      );
      rethrow;
    }
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    SdLogger.action(
      LogTagConstant.profile,
      'Write profile name',
      <String, Object?>{'uid': uid, 'length': displayName.length},
    );
    try {
      await _doc(uid).set(<String, Object?>{
        UserProfileMapper.displayNameField: displayName,
        UserProfileMapper.updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      SdLogger.info(
        LogTagConstant.profile,
        'Profile name written',
        <String, Object?>{'uid': uid},
      );
    } on FirebaseException catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.profile,
        'Write profile name failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'uid': uid, 'code': error.code},
      );
      rethrow;
    }
  }
}
