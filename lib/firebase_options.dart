import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {

  static const FirebaseOptions web = FirebaseOptions(

    apiKey: 'AIzaSyAva3wH9PYCh3u_PodvqNHzkkf4K5o04pE',

    authDomain: 'hermona-6a626.firebaseapp.com',

    projectId: 'hermona-6a626',

    storageBucket: 'hermona-6a626.firebasestorage.app',

    messagingSenderId: '283017326348',

    appId: '1:283017326348:web:0000000000000000000000',

    databaseURL:

        'https://hermona-6a626-default-rtdb.europe-west1.firebasedatabase.app',

  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return web; // Mocking with web for now
      case TargetPlatform.iOS:
        return web;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }
}
