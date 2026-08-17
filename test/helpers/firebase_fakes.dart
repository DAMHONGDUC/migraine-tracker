/// Hand-rolled stand-ins for the four Firebase SDK types
/// `FirebaseAlertRegistrationRepository` takes.
///
/// **Why these exist rather than a mocking package.** Those types are
/// concrete and enormous, and `docs/REMAINING_WORK.md` item 19 read that as a
/// choice between extracting three interfaces and adding `mockito`. There is
/// a third way: a class that declares `noSuchMethod` no longer has to
/// implement the rest of its interface — which is what mockito generates
/// anyway. So each fake below overrides the two or three members the
/// repository actually calls, and `super.noSuchMethod` turns anything else
/// into a `NoSuchMethodError` naming the member. **That failure is the point**:
/// a test that reaches past what the repository is supposed to touch fails
/// loudly instead of quietly passing.
///
/// The cost is that a Firebase SDK upgrade can change a signature under
/// these. That is a compile error in a test file, which is the cheap end of
/// the ways an SDK upgrade can break a repo.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Signed out by default — the state `_uid()` refuses.
class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.user});

  FakeUser? user;

  @override
  FakeUser? get currentUser => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  const FakeUser({this.uid = 'uid-1', this.isAnonymous = false});

  @override
  final String uid;

  /// An anonymous session is refused exactly like a signed-out one: alerts
  /// need premium and premium needs an account (hard rule 7).
  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Granted permission and a token, unless a test says otherwise.
class FakeFirebaseMessaging implements FirebaseMessaging {
  FakeFirebaseMessaging({
    this.status = AuthorizationStatus.authorized,
    this.token = 'token-1',
  });

  final AuthorizationStatus status;

  /// Null is an iOS simulator: no APNs, so no token, which is not a refusal.
  final String? token;

  int permissionRequests = 0;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionRequests++;

    return NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => token;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One document, whatever path is asked for. The repository only ever writes
/// `users/{uid}`, and the test asserts the path it was given.
class FakeFirebaseFirestore implements FirebaseFirestore {
  FakeFirebaseFirestore({FakeDocumentReference? document})
    : document = document ?? FakeDocumentReference();

  /// Shared by every path, so a test can inspect it without knowing the uid.
  final FakeDocumentReference document;

  final List<String> collectionPaths = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    collectionPaths.add(collectionPath);

    return FakeCollectionReference(document);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(this.document);

  final FakeDocumentReference document;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    document.paths.add(path);

    return document;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  FakeDocumentReference({this.setThrows, this.updateThrows});

  /// Thrown by [set] / [update] — the offline and rules-refused paths.
  final Exception? setThrows;
  final Exception? updateThrows;

  /// The doc ids `doc(...)` was called with.
  final List<String?> paths = <String?>[];

  /// Every write, in order, with the options it carried.
  final List<Map<String, Object?>> sets = <Map<String, Object?>>[];
  final List<SetOptions?> setOptions = <SetOptions?>[];
  final List<Map<Object, Object?>> updates = <Map<Object, Object?>>[];

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (setThrows != null) throw setThrows!;
    sets.add(data);
    setOptions.add(options);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (updateThrows != null) throw updateThrows!;
    updates.add(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFunctions implements FirebaseFunctions {
  FakeFirebaseFunctions({FakeHttpsCallable? callable})
    : callable = callable ?? FakeHttpsCallable();

  final FakeHttpsCallable callable;

  final List<String> names = <String>[];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    names.add(name);

    return callable;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallable implements HttpsCallable {
  FakeHttpsCallable({this.throws});

  /// Thrown by [call] — what the backend refusing looks like.
  Exception? throws;

  int calls = 0;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    if (throws != null) throw throws!;
    calls++;

    return FakeHttpsCallableResult<T>(null as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);

  @override
  final T data;
}
