import 'package:flutter/material.dart';

import 'Back-office/Coach/coach_routes.dart';
import 'Back-office/Players/player_routes.dart';
import 'Back-office/Shared/shared_routes.dart';


class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
        // Debug route name
 // Shared routes
    final sharedRoute = SharedRoutes.getRoute(settings);
    if (sharedRoute != null) {
      return sharedRoute;
    }

 // Coach routes
    final coachRoute = CoachRoutes.getRoute(settings);
    if (coachRoute != null) {
      return coachRoute;
    }
   
    // Player routes
    final playerRoute = PlayerRoutes.getRoute(settings);
    if (playerRoute != null) {
      return playerRoute;
    }
    // Default error route
    return _errorRoute();
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
