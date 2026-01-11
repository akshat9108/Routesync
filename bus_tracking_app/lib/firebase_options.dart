// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // 🌐 Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC0uIN1hqJcELqJqqjbr1C4bxFWBpsdvGQ",
    authDomain: "bus-tracking-app-e6ddf.firebaseapp.com",
    databaseURL: "https://bus-tracking-app-e6ddf-default-rtdb.firebaseio.com",
    projectId: "bus-tracking-app-e6ddf",
    storageBucket: "bus-tracking-app-e6ddf.firebasestorage.app",
    messagingSenderId: "293666738073",
    appId: "1:293666738073:web:8fc7e1c4747ba7cae40d08",
    measurementId: "G-034B9Y2KE5",
  );

  // 📱 Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCFqwppeYOHt8fnecAEO5bNW8mgbrTK1n8",
    appId: "1:293666738073:android:05e21c57368d2260e40d08",
    messagingSenderId: "293666738073",
    projectId: "bus-tracking-app-e6ddf",
    storageBucket: "bus-tracking-app-e6ddf.firebasestorage.app",
    databaseURL: "https://bus-tracking-app-e6ddf-default-rtdb.firebaseio.com",
  );
}
