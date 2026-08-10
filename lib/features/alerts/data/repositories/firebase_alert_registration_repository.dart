import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  Future<String> _uid() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<void> register({required double thresholdHpa}) async {
    try {
      final uid = await _uid();

      final permission = await _messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw const AlertRegistrationException(
          AlertRegistrationError.notificationsDenied,
        );
      }

      final point = await _location.currentPosition();
      if (point == null) {
        throw const AlertRegistrationException(
          AlertRegistrationError.locationUnavailable,
        );
      }

      // Null on iOS simulators (no APNS) — real devices and Android work.
      final token = await _messaging.getToken();
      if (token == null) {
        throw const AlertRegistrationException(
          AlertRegistrationError.pushUnavailable,
        );
      }

      await _firestore.collection('users').doc(uid).set({
        'geohash5': Geohash.encode(point.latitude, point.longitude),
        'fcmToken': token,
        'alertThreshold': thresholdHpa,
        'tz': DateTime.now().timeZoneName,
      }, SetOptions(merge: true));
    } on AlertRegistrationException {
      rethrow;
    } on Exception {
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
  Future<void> forgetRegistration() => _clear(<String>[
    'fcmToken',
    'geohash5',
    'alertThreshold',
    'tz',
  ]);

  @override
  Future<void> sendTestPush() =>
      _functions.httpsCallable(testPushCallable).call<dynamic>();

  /// An update, never a delete: the document also carries `premium`, which
  /// only the RevenueCat webhook may write and which the rules refuse to let
  /// a client touch — a delete would take it with it, and a paying
  /// subscriber would silently stop receiving alerts.
  Future<void> _clear(List<String> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update(<String, Object?>{
        for (final String field in fields) field: FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      // Doc never created — nothing to forget.
      if (e.code != 'not-found') rethrow;
    }
  }
}
