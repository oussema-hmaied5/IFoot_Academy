import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'Pages/app_routes.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

   // Initialize Firebase App Check with Play Integrity
 // ✅ Enable Debug Token for Emulator
  bool isDebugMode = false;
  assert(() {
    isDebugMode = true;
    return true;
  }());

  await FirebaseAppCheck.instance.activate(
    androidProvider: isDebugMode
        ? AndroidProvider.debug // ✅ Use Debug Mode for Emulator
        : AndroidProvider.playIntegrity, // ✅ Use Play Integrity for Production
    appleProvider: AppleProvider.appAttest,
  );

  FirebaseApp app = Firebase.app();
  print("🔥 Firebase initialized: ${app.name}");
  print("📦 Firebase Storage Bucket: ${app.options.storageBucket}");

  await initializeDateFormatting('fr_FR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        title: 'iFoot Academy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        onGenerateRoute:
            AppRoutes.generateRoute, // Use the centralized route generator
      ),
    );
  }
}
