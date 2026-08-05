// - Hand-edited from FlutterFire CLI output: values come from `AppEnv` (--dart-define-from-file=env/<flavor>.json).
// - Non-secret client identifiers (real access control is Firestore Rules), kept out of git to avoid leaking the project.
// - Rerunning `flutterfire configure` overwrites this — reapply from git history after.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/env/app_env.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: AppEnv.firebaseAndroidApiKey,
    appId: AppEnv.firebaseAndroidAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    storageBucket: AppEnv.firebaseStorageBucket,
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: AppEnv.firebaseIosApiKey,
    appId: AppEnv.firebaseIosAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    storageBucket: AppEnv.firebaseStorageBucket,
    iosBundleId: AppEnv.firebaseIosBundleId,
  );
}
