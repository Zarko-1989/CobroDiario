// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyD5hK8ehhFtPND9hNIZXW6yvpw6RmLXa54',
    appId: '1:588314232678:web:5f2520ec505612e369eaa7',
    messagingSenderId: '588314232678',
    projectId: 'pagosdiarios-de9c6',
    authDomain: 'pagosdiarios-de9c6.firebaseapp.com',
    databaseURL: 'https://pagosdiarios-de9c6-default-rtdb.firebaseio.com',
    storageBucket: 'pagosdiarios-de9c6.appspot.com',
    measurementId: 'G-CRVQF5PJGX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNe-AivF72Df5HKP0lnJ2BK6TxIa--qxA',
    appId: '1:588314232678:android:d4ddcd996a25397369eaa7',
    messagingSenderId: '588314232678',
    projectId: 'pagosdiarios-de9c6',
    databaseURL: 'https://pagosdiarios-de9c6-default-rtdb.firebaseio.com',
    storageBucket: 'pagosdiarios-de9c6.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD5hK8ehhFtPND9hNIZXW6yvpw6RmLXa54',
    appId: '1:588314232678:web:87bcf257d445f22569eaa7',
    messagingSenderId: '588314232678',
    projectId: 'pagosdiarios-de9c6',
    authDomain: 'pagosdiarios-de9c6.firebaseapp.com',
    databaseURL: 'https://pagosdiarios-de9c6-default-rtdb.firebaseio.com',
    storageBucket: 'pagosdiarios-de9c6.appspot.com',
    measurementId: 'G-YS3CHC1MDN',
  );
}
