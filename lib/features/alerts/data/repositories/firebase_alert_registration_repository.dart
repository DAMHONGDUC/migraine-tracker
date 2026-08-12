import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../weather/data/datasources/location_source.dart';
import '../../domain/enums/alert_registration_error.dart';
import '../../domain/repositories/alert_registration_repository.dart';
import '../../domain/services/geohash.dart';

class FirebaseAlertRegistrationRepository
    implements AlertRegistrationRepository {
  const FirebaseAlertRegistrationRepository(
    this._auth,
    this._messaging,
    this._firestore,
    this._location,
    this._functions,
  );

  /// Pushes to the caller's own device. Dev tooling — see `sendTestPush`.
  static const String testPushCallable = 'sendTestPush';

  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final LocationSource _location;
  final FirebaseFunctions _functions;

  /// The signed-in account's uid. Throws when there is not one.
  ///
  /// **No anonymous fallback.** Alerts need premium and premium needs an
  /// account (hard rule 7), so a session without one can never reach the push
  /// path — registering it would write a `users/{uid}` doc the cron will never
  /// read, and quietly create an account the user never asked for. This used
  /// to call `signInAnonymously`, which is exactly that.
  Future<String> _uid() async {
    final User? user = _auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw const AlertRegistrationException(
        AlertRegistrationError.accountRequired,
      );
    }

    return user.uid;
  }

  /// This device's FCM token, after the permission prompt.
  ///
  /// Shared by [register] and [sendTestPush]: the two write different fields,
  /// but both need the same prompt and the same token.
  Future<String> _pushToken() async {
    final NotificationSettings permission = await _messaging
        .requestPermission();

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw const AlertRegistrationException(
        AlertRegistrationError.notificationsDenied,
      );
    }

    // Null on iOS simulators (no APNS) — real devices and Android work.
    final String? token = await _messaging.getToken();

    if (token == null) {
      throw const AlertRegistrationException(
        AlertRegistrationError.pushUnavailable,
      );
    }

    return token;
  }

  @override
  Future<void> register({required double thresholdHpa}) async {
    try {
      final String uid = await _uid();
      final String token = await _pushToken();
      final point = await _location.currentPosition();

      if (point == null) {
        throw const AlertRegistrationException(
          AlertRegistrationError.locationUnavailable,
        );
      }

      await _firestore.collection('users').doc(uid).set({
        'geohash5': Geohash.encode(point.latitude, point.longitude),
        'fcmToken': token,
        'alertThreshold': thresholdHpa,
        'tz': DateTime.now().timeZoneName,
      }, SetOptions(merge: true));
      AppLogger.info('Alerts registered', {'thresholdHpa': thresholdHpa});
    } on AlertRegistrationException {
      rethrow;
    } catch (error, stackTrace) {
      // The mapping to `unknown` is what the UI needs and what the console
      // must not be left with — the real exception is only ever seen here.
      AppLogger.error(
        'Alerts registration failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw const AlertRegistrationException(AlertRegistrationError.unknown);
    }
  }

  @override
  Future<void> updateThreshold(double thresholdHpa) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'alertThreshold': thresholdHpa,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> unregister() => _clear(<String>['fcmToken']);

  @override
  Future<void> forgetRegistration() =>
      _clear(<String>['fcmToken', 'geohash5', 'alertThreshold', 'tz']);

  @override
  Future<void> sendTestPush() async {
    final String uid = await _uid();
    final String token = await _pushToken();

    // The callable pushes to whatever token the backend holds, so registering
    // is part of the test rather than a precondition of it.
    await _firestore.collection('users').doc(uid).set(<String, Object?>{
      'fcmToken': token,
    }, SetOptions(merge: true));
    AppLogger.info('Push token registered', {'uid': uid});

    await _functions.httpsCallable(testPushCallable).call<dynamic>();
    AppLogger.info('Test push requested');
  }

  /// An update, never a delete: the document also carries `premium`, which
  /// only the RevenueCat webhook may write and which the rules refuse to let
  /// a client touch — a delete would take it with it, and a paying
  /// subscriber would silently stop receiving alerts.
  Future<void> _clear(List<String> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update(
        <String, Object?>{
          for (final String field in fields) field: FieldValue.delete(),
        },
      );
    } on FirebaseException catch (error, stackTrace) {
      // Doc never created — nothing to forget.
      if (error.code == 'not-found') return;

      AppLogger.error(
        'Clearing alert registration failed',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
}
