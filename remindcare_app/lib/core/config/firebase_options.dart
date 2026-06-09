// PENTING: File ini di-generate otomatis oleh FlutterFire CLI.
// Jangan edit manual!
//
// Cara generate:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//
// Atau download google-services.json dari Firebase Console
// dan taruh di android/app/

// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak dikonfigurasi untuk platform ini. '
          'Jalankan: flutterfire configure');
    }
  }

  // ── Ganti semua nilai di bawah dengan nilai dari Firebase Console ──
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'YOUR_ANDROID_API_KEY',
    appId:             '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId:         'your-firebase-project-id',
    storageBucket:     'your-firebase-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY',
    appId:             '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId:         'your-firebase-project-id',
    storageBucket:     'your-firebase-project-id.appspot.com',
    iosBundleId:       'com.remindcare.remindcareApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'YOUR_WEB_API_KEY',
    appId:             '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId:         'your-firebase-project-id',
    storageBucket:     'your-firebase-project-id.appspot.com',
    authDomain:        'your-firebase-project-id.firebaseapp.com',
  );
}
