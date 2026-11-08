import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBaNxMcqU28Kl_fYv296RUEKzrEQBbEBAM',
    appId: '1:144237882397:web:admin',
    messagingSenderId: '144237882397',
    projectId: 'poke-iring',
    authDomain: 'poke-iring.firebaseapp.com',
    storageBucket: 'poke-iring.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBaNxMcqU28Kl_fYv296RUEKzrEQBbEBAM',
    appId: '1:144237882397:android:529c02c60488916e46aaf4',
    messagingSenderId: '144237882397',
    projectId: 'poke-iring',
    storageBucket: 'poke-iring.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBaNxMcqU28Kl_fYv296RUEKzrEQBbEBAM',
    appId: '1:144237882397:ios:529c02c60488916e46aaf4',
    messagingSenderId: '144237882397',
    projectId: 'poke-iring',
    storageBucket: 'poke-iring.firebasestorage.app',
  );
}
