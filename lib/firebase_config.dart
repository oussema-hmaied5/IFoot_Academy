import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; 

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyAdO9VNoFopMd9J_A7502Izb06EcYfF7u4',
        appId: Platform.isIOS 
          ? '1:606424227576:ios:7fd436184a1092f922250d'   // iOS App ID
          : '1:606424227576:android:a01f2ed0a0a4eace22250d', // Android App ID
        messagingSenderId: '606424227576',
        projectId: 'ifoot-3253a',
        storageBucket: 'ifoot-3253a.firebasestorage.app',
      ),
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );

  }
}