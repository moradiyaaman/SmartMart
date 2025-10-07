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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyBqJ5XXXXXXXXXXXXXXXXXXXXXXXXXXX', // Replace with your actual Web API key
    appId: '1:123456789:web:abcdefghijklmnop', // Replace with your actual Web App ID
    messagingSenderId: '123456789', // Replace with your actual Sender ID
    projectId: 'smartmart-demo', // Replace with your actual Project ID
    authDomain: 'smartmart-demo.firebaseapp.com',
    storageBucket: 'smartmart-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqJ5XXXXXXXXXXXXXXXXXXXXXXXXXXX', // Replace with your actual Android API key
    appId: '1:123456789:android:abcdefghijk123456', // Replace with your actual Android App ID
    messagingSenderId: '123456789', // Replace with your actual Sender ID
    projectId: 'smartmart-demo', // Replace with your actual Project ID
    storageBucket: 'smartmart-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqJ5XXXXXXXXXXXXXXXXXXXXXXXXXXX', // Replace with your actual iOS API key
    appId: '1:123456789:ios:abcdefghijk123456', // Replace with your actual iOS App ID
    messagingSenderId: '123456789', // Replace with your actual Sender ID
    projectId: 'smartmart-demo', // Replace with your actual Project ID
    storageBucket: 'smartmart-demo.appspot.com',
    iosClientId: '123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com',
    iosBundleId: 'com.example.smartmart',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqJ5XXXXXXXXXXXXXXXXXXXXXXXXXXX', // Replace with your actual iOS API key
    appId: '1:123456789:ios:abcdefghijk123456', // Replace with your actual iOS App ID
    messagingSenderId: '123456789', // Replace with your actual Sender ID
    projectId: 'smartmart-demo', // Replace with your actual Project ID
    storageBucket: 'smartmart-demo.appspot.com',
    iosClientId: '123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com',
    iosBundleId: 'com.example.smartmart',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBqJ5XXXXXXXXXXXXXXXXXXXXXXXXXXX', // Replace with your actual Web API key
    appId: '1:123456789:web:abcdefghijklmnop', // Replace with your actual Web App ID
    messagingSenderId: '123456789', // Replace with your actual Sender ID
    projectId: 'smartmart-demo', // Replace with your actual Project ID
    authDomain: 'smartmart-demo.firebaseapp.com',
    storageBucket: 'smartmart-demo.appspot.com',
  );
}
