// Based on FlutterFire CLI output, hand-edited so the values come from the
// central `Env` class (fed by --dart-define-from-file=env/<flavor>.json)
// instead of being hardcoded. Firebase treats these as non-secret client
// identifiers, not credentials — real access control is Firestore Security
// Rules — but keeping them out of git avoids leaking which project backs
// the app and keeps rotation easy.
//
// If you rerun `flutterfire configure`, reapply this file from git history —
// it will overwrite these edits with hardcoded values again.
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
