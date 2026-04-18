// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 🔹 WEB CONFIG
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDUJ9CZvUGo3wBGrL2uJb9KsF7FGp3YKpU",
    authDomain: "naam-160ac.firebaseapp.com",
    projectId: "naam-160ac",
    storageBucket: "naam-160ac.firebasestorage.app",
    messagingSenderId: "203752329664",
    appId: "1:203752329664:web:c4225c7e65ea90f0c4b825",
    measurementId: "G-E17C31Y0PG",
  );

  // 🔹 ANDROID CONFIG
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCIiZ-Yd46BmqWCLVXBhzji4MSqtJ6f3kY",
    appId: "1:203752329664:android:0b69d776e4d33785c4b825",
    messagingSenderId: "203752329664",
    projectId: "naam-160ac",
    storageBucket: "naam-160ac.firebasestorage.app",
  );
}