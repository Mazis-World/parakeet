// Placeholder Firebase options for web
// This file is used when firebase_options.dart is not available
// Generate the actual file using: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web placeholder - replace with actual config
      return const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
      );
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
}

