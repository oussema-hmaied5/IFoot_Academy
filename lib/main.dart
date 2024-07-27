import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/data/auth_api.dart';  // Import the AuthApi file
import 'package:ifoot_academy/epics/app_epics.dart';  // Import the AppEpics file
import 'package:ifoot_academy/models/app_state.dart';
import 'package:ifoot_academy/presantation/login_page.dart';
import 'package:ifoot_academy/presantation/main_page.dart';
import 'package:ifoot_academy/presantation/register_page.dart';
import 'package:ifoot_academy/reducers/app_reducer.dart';
import 'package:ifoot_academy/splash_screen.dart';
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  final AuthApi authApi = AuthApi();  // Create an instance of AuthApi
  final AppEpics appEpics = AppEpics(authApi: authApi);  // Create an instance of AppEpics

  final Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [EpicMiddleware(appEpics.epics)],  // Add the EpicMiddleware
  );

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  const MyApp({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        title: 'iFoot Academy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/splash',  // Set the initial route
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) => const MainPage(),
          '/register': (context) => const RegisterPage(),
          '/splash': (context) => SplashScreen(),  // Define your routes
        },
      ),
    );
  }
}
