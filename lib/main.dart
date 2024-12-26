import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Authentification/login_page.dart';
import 'package:ifoot_academy/Pages/Authentification/register_page.dart';
import 'package:ifoot_academy/Pages/Backend/Profile/detailprofil_page.dart';
import 'package:ifoot_academy/Pages/Frontend/User/user_home_page.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'Pages/Authentification/passwordResetPage.dart';
import 'Pages/Authentification/services/AuthProvider.dart';
import 'Pages/Authentification/verificationCodePage.dart';
import 'Pages/Backend/Calender/training_page.dart';
import 'Pages/Backend/Events/events_page.dart';
import 'Pages/Backend/Groupes/add_groupe_page.dart';
import 'Pages/Backend/Groupes/all_groupes_page.dart';
import 'Pages/Backend/Menu/admin_page.dart';
import 'Pages/Backend/Regulation/regulation_page.dart';
import 'Pages/Backend/Users/all_users_page.dart';
import 'Pages/Frontend/User/Groupe_Front/myteam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz_data.initializeTimeZones();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeUser()),
      ],
      child: MaterialApp(
        title: 'iFoot Academy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case '/main':
        if (settings.arguments is String) {
          final userId = settings.arguments as String;
          return MaterialPageRoute(builder: (context) => UserHomePage(userId: userId));
        }
        return _errorRoute();
        
      case '/register':
        return MaterialPageRoute(builder: (context) => const RegisterPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (context) => PasswordResetPage());
      case '/verify-code':
        if (settings.arguments is String) {
          final email = settings.arguments as String;
          return MaterialPageRoute(builder: (context) => VerificationCodePage(email: email));
        }
        return _errorRoute();
      case '/admin':
        return MaterialPageRoute(builder: (context) => const AdminMainPage());
      case '/profile':
        if (settings.arguments is String) {
          final userId = settings.arguments as String;
          return MaterialPageRoute(builder: (context) => ProfileDetailsPage(userId: userId));
        }
        return _errorRoute();
      case '/manageUsers':
        return MaterialPageRoute(builder: (context) => const ManageUsersPage());
        
      case '/myTeam':
        return MaterialPageRoute(builder: (context) => const MyTeamPage());
      case '/manageGroups':
        return MaterialPageRoute(builder: (context) => const ManageGroupsPage());
      case '/AjoutGroups':
        return MaterialPageRoute(builder: (context) => const AddGroupPage());
      case '/manageEvents':
        return MaterialPageRoute(builder: (context) => const ManageEventsPage());
      case '/manageRegulations':
        return MaterialPageRoute(builder: (context) => const ManageRegulationsPage());
      case '/manageTraining':
        return MaterialPageRoute(builder: (context) => const TrainingCalendarPage());
      default:
        return _errorRoute();
    }
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
