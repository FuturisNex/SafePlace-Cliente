// File generated from google-services.json
// Firebase project: safeplate-a14e9

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhAWZ61YF4Qhl_GJjRl6avMpkUZuK6n8k',
    appId: '1:476899420653:web:fcd5a28dc225e9ae03dfe4', // Placeholder based on Android/iOS pattern
    messagingSenderId: '476899420653',
    projectId: 'safeplate-a14e9',
    authDomain: 'safeplate-a14e9.firebaseapp.com',
    storageBucket: 'safeplate-a14e9.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhAWZ61YF4Qhl_GJjRl6avMpkUZuK6n8k',
    appId: '1:476899420653:android:fcd5a28dc225e9ae03dfe4',
    messagingSenderId: '476899420653',
    projectId: 'safeplate-a14e9',
    storageBucket: 'safeplate-a14e9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhAWZ61YF4Qhl_GJjRl6avMpkUZuK6n8k',
    appId: '1:476899420653:ios:fcd5a28dc225e9ae03dfe4',
    messagingSenderId: '476899420653',
    projectId: 'safeplate-a14e9',
    storageBucket: 'safeplate-a14e9.firebasestorage.app',
    iosBundleId: 'br.com.pratoseguro.app',
  );
}
