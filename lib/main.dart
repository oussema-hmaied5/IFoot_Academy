// ignore_for_file: empty_catches

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/models/app_state.dart';
import 'package:ifoot_academy/presantation/Admin/Menu/admin_page.dart';
import 'package:ifoot_academy/presantation/Authentification/login_page.dart';
import 'package:ifoot_academy/presantation/Authentification/register_page.dart';
import 'package:ifoot_academy/presantation/Profile/detailprofil_page.dart';
import 'package:ifoot_academy/presantation/main_page.dart';
import 'package:ifoot_academy/reducers/app_reducer.dart';
import 'package:ifoot_academy/services/auth_service.dart'; // Import the AuthApi file
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';

import 'presantation/Admin/Events/events_page.dart';
import 'presantation/Admin/Groupes/all_groupes_page.dart';
import 'presantation/Admin/Regulation/regulation_page.dart';
import 'presantation/Admin/Users/all_users_page.dart';
import 'presantation/Calender/training_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {}

  final AuthApi authApi = AuthApi(); // Create an instance of AuthApi
  final AppEpics appEpics =
      AppEpics(authApi: authApi); // Create an instance of AppEpics

  final Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    middleware: [EpicMiddleware(appEpics.epics)], // Add the EpicMiddleware
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
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) => const MainPage(),
          '/register': (context) => const RegisterPage(),
          '/admin': (context) => const AdminMainPage(),
          '/profile': (context) => const ProfileDetailsPage(),
          '/manageUsers': (context) => const ManageUsersPage(),
          '/manageGroups': (context) => const ManageGroupsPage(),
          '/manageEvents': (context) => const ManageEventsPage(),
          '/manageRegulations': (context) => const ManageRegulationsPage(),
          '/manageTraining': (context) => const TrainingCalendarPage(),
        },
      ),
    );
  }
}
