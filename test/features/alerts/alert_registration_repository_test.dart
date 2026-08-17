import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/alerts/data/repositories/firebase_alert_registration_repository.dart';
import 'package:migraine_tracker/features/alerts/domain/enums/alert_registration_error.dart';
import 'package:migraine_tracker/features/weather/data/datasources/location_source.dart';
import 'package:migraine_tracker/features/weather/domain/entities/geo_point.dart';

import '../../helpers/firebase_fakes.dart';

/// The ordinary caller: signed in with a real account.
const FakeUser _signedIn = FakeUser();

/// Hanoi, which `geohash_test.dart` and the backend both agree is `w7er8`.
const GeoPoint _hanoi = GeoPoint(latitude: 21.03, longitude: 105.85);

/// Answers one fixed position, or none. The dev `FakeLocationSource` in `lib/`
/// always has a point, and half of these cases are about not having one.
class _StubLocationSource implements LocationSource {
  const _StubLocationSource([this.point]);

  final GeoPoint? point;

  @override
  Future<GeoPoint?> currentPosition() async => point;

  @override
  Future<bool> requestPermission() async => point != null;
}

void main() {
  ({
    FirebaseAlertRegistrationRepository repository,
    FakeFirebaseAuth auth,
    FakeFirebaseMessaging messaging,
    FakeFirebaseFirestore firestore,
    FakeFirebaseFunctions functions,
  })
  harness({
    FakeUser? user = _signedIn,
    AuthorizationStatus status = AuthorizationStatus.authorized,
    String? token = 'token-1',
    GeoPoint? position = _hanoi,
    Exception? setThrows,
    Exception? updateThrows,
  }) {
    final FakeFirebaseAuth auth = FakeFirebaseAuth(user: user);
    final FakeFirebaseMessaging messaging = FakeFirebaseMessaging(
      status: status,
      token: token,
    );
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore(
      document: FakeDocumentReference(
        setThrows: setThrows,
        updateThrows: updateThrows,
      ),
    );
    final FakeFirebaseFunctions functions = FakeFirebaseFunctions();

    return (
      repository: FirebaseAlertRegistrationRepository(
        auth,
        messaging,
        firestore,
        _StubLocationSource(position),
        functions,
      ),
      auth: auth,
      messaging: messaging,
      firestore: firestore,
      functions: functions,
    );
  }

  group('register', () {
    test('writes the four fields, merged, to the caller own users doc', () async {
      final harnessed = harness();

      await harnessed.repository.register(thresholdHpa: 7.5);

      expect(harnessed.firestore.collectionPaths, <String>['users']);
      expect(harnessed.firestore.document.paths, <String?>['uid-1']);
      // Hard rule 1: the doc holds these four and nothing else — no health
      // data, and never `premium`, which is the webhook's to write.
      expect(harnessed.firestore.document.sets.single.keys, <String>[
        'geohash5',
        'fcmToken',
        'alertThreshold',
        'tz',
      ]);
      expect(harnessed.firestore.document.sets.single['geohash5'], 'w7er8');
      expect(harnessed.firestore.document.sets.single['fcmToken'], 'token-1');
      expect(harnessed.firestore.document.sets.single['alertThreshold'], 7.5);
      // Merge, never a plain set: a plain one would take `premium` with it.
      expect(harnessed.firestore.document.setOptions.single?.merge, isTrue);
    });

    test('refuses a signed-out device and writes nothing', () async {
      final harnessed = harness(user: null);

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.accountRequired,
          ),
        ),
      );
      expect(harnessed.firestore.document.sets, isEmpty);
      // It must not even ask for notification permission: the prompt is spent
      // once, and spending it on a device that cannot register wastes it.
      expect(harnessed.messaging.permissionRequests, isZero);
    });

    /// Hard rule 7: premium needs an account, alerts need premium, so an
    /// anonymous session can never reach the push path.
    test('refuses an anonymous session exactly like a signed-out one', () async {
      final harnessed = harness(user: FakeUser(isAnonymous: true));

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.accountRequired,
          ),
        ),
      );
      expect(harnessed.firestore.document.sets, isEmpty);
    });

    test('maps a denied permission to notificationsDenied', () async {
      final harnessed = harness(status: AuthorizationStatus.denied);

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.notificationsDenied,
          ),
        ),
      );
      expect(harnessed.firestore.document.sets, isEmpty);
    });

    /// The simulator case: APNs does not exist there, so `getToken` answers
    /// null. It is not a refusal and must not be reported as one.
    test('maps a null token to pushUnavailable', () async {
      final harnessed = harness(token: null);

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.pushUnavailable,
          ),
        ),
      );
    });

    test('maps a missing position to locationUnavailable', () async {
      final harnessed = harness(position: null);

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.locationUnavailable,
          ),
        ),
      );
      expect(harnessed.firestore.document.sets, isEmpty);
    });

    /// The console keeps the real exception; the UI gets an enum it can
    /// render. What must never happen is the raw Firebase error reaching a
    /// screen.
    test('maps an unexpected write failure to unknown', () async {
      final harnessed = harness(
        setThrows: FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );

      await expectLater(
        harnessed.repository.register(thresholdHpa: 5),
        throwsA(
          isA<AlertRegistrationException>().having(
            (e) => e.error,
            'error',
            AlertRegistrationError.unknown,
          ),
        ),
      );
    });
  });

  group('updateThreshold', () {
    test('writes only the threshold, merged', () async {
      final harnessed = harness();

      await harnessed.repository.updateThreshold(9);

      expect(harnessed.firestore.document.sets.single, <String, Object?>{
        'alertThreshold': 9.0,
      });
      expect(harnessed.firestore.document.setOptions.single?.merge, isTrue);
    });

    test('does nothing at all without an account', () async {
      final harnessed = harness(user: null);

      await harnessed.repository.updateThreshold(9);

      expect(harnessed.firestore.document.sets, isEmpty);
    });
  });

  group('unregister', () {
    /// Only the token: turning alerts off must not forget the threshold the
    /// user chose, which they will want back when they turn them on again.
    test('deletes the token and leaves the threshold alone', () async {
      final harnessed = harness();

      await harnessed.repository.unregister();

      expect(harnessed.firestore.document.updates.single.keys, <Object>[
        'fcmToken',
      ]);
      expect(
        harnessed.firestore.document.updates.single['fcmToken'],
        isA<FieldValue>(),
      );
    });

    /// An update, never a delete: the doc also carries `premium`, and a
    /// delete would take a paying subscriber's alerts with it.
    test('swallows not-found — there was nothing to forget', () async {
      final harnessed = harness(
        updateThrows: FirebaseException(
          plugin: 'firestore',
          code: 'not-found',
        ),
      );

      await expectLater(harnessed.repository.unregister(), completes);
    });

    test('rethrows any other Firebase failure', () async {
      final harnessed = harness(
        updateThrows: FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
        ),
      );

      await expectLater(
        harnessed.repository.unregister(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  group('forgetRegistration', () {
    /// The GDPR wipe: nothing may survive that could still reach the user or
    /// say where they were.
    test('deletes the token, the geohash, the threshold and the zone', () async {
      final harnessed = harness();

      await harnessed.repository.forgetRegistration();

      expect(harnessed.firestore.document.updates.single.keys, <Object>[
        'fcmToken',
        'geohash5',
        'alertThreshold',
        'tz',
      ]);
    });

    test('does nothing at all without an account', () async {
      final harnessed = harness(user: null);

      await harnessed.repository.forgetRegistration();

      expect(harnessed.firestore.document.updates, isEmpty);
    });
  });

  group('sendTestPush', () {
    /// It registers the token itself rather than requiring `register` to have
    /// run: the token is only written when alerts are turned on, which needs
    /// premium and a location fix.
    test('writes the token, then calls the backend', () async {
      final harnessed = harness();

      await harnessed.repository.sendTestPush();

      expect(harnessed.firestore.document.sets.single, <String, Object?>{
        'fcmToken': 'token-1',
      });
      expect(harnessed.functions.names, <String>[
        FirebaseAlertRegistrationRepository.testPushCallable,
      ]);
      expect(harnessed.functions.callable.calls, 1);
    });

    test('refuses an anonymous session and never reaches the callable', () async {
      final harnessed = harness(user: FakeUser(isAnonymous: true));

      await expectLater(
        harnessed.repository.sendTestPush(),
        throwsA(isA<AlertRegistrationException>()),
      );
      expect(harnessed.functions.callable.calls, isZero);
    });

    /// Unlike `register`, this one does NOT map its failures: the dev row
    /// that calls it wants the backend's own code (`unauthenticated`,
    /// `permission-denied`, `failed-precondition`), which is the whole
    /// diagnostic.
    test('lets the callable failure through unmapped', () async {
      final harnessed = harness();
      final FakeFirebaseFunctions functions = harnessed.functions;

      functions.callable.throws = FirebaseException(
        plugin: 'functions',
        code: 'failed-precondition',
      );

      await expectLater(
        harnessed.repository.sendTestPush(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
