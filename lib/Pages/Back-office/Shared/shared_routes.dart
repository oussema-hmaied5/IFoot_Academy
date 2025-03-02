import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Authentification/login_page.dart';
import 'package:ifoot_academy/Pages/Authentification/passwordResetPage.dart';
import 'package:ifoot_academy/Pages/Authentification/register_page.dart';
import 'package:ifoot_academy/Pages/Back-office/Menu/admin_page.dart';
import 'package:ifoot_academy/Pages/Style/animation/splash_screen.dart';

class SharedRoutes {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/forget-password':
        return MaterialPageRoute(builder: (_) =>  const PasswordResetPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/admin':
        final args = settings.arguments;
        bool isCoach = false; // Default value
        if (args is Map<String, dynamic> && args.containsKey('isCoach')) {
          isCoach = args['isCoach'] as bool;
        }
        return MaterialPageRoute(
          builder: (_) => const AdminMainPage(),
          settings: RouteSettings(
            arguments: {'isCoach': isCoach},
          ),
        );
      default:
        return null;
    }
  }
}
