import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/Coach/gestion_coach/add_coach_page.dart';
import 'package:ifoot_academy/Pages/Back-office/Coach/gestion_coach/edit_coach_page.dart';
import 'package:ifoot_academy/Pages/Back-office/Coach/gestion_coach/manage_coaches_page.dart';

import 'gestion_planing/coach_plannings_page.dart';
import 'gestion_planing/planning_form_page.dart';
import 'gestion_planing/planning_overview_page.dart';
import 'gestion_planing/planning_stats_page.dart';

class CoachRoutes {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    print('CoachRoutes: Checking route ${settings.name}'); // Debugging

    switch (settings.name) {
      case '/AllCoaches':
        return MaterialPageRoute(builder: (_) => const ManageCoachesPage());

      case '/addCoach':
        return MaterialPageRoute(builder: (_) => const AddCoachPage());

      case '/editCoach':
        if (settings.arguments is String) {
          final coachId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => EditCoachPage(coachId: coachId),
          );
        }
        print('Invalid arguments for /editCoach');
        return null;

      case '/CoachPlanning':
        if (settings.arguments is String) {
          final coachId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => CoachPlanningPage(coachId: coachId),
          );
        }
        print('Invalid arguments for /CoachPlanning');
        return null;

      case '/PlanningForm':
        if (settings.arguments is Map<String, dynamic>?) {
          final session = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => PlanningFormPage(session: session),
          );
        }
        print('Invalid arguments for /PlanningForm');
        return null;

      case '/PlanningOverview':
        return MaterialPageRoute(builder: (_) => const PlanningOverviewPage());

      case '/coachStats':
        return MaterialPageRoute(builder: (_) => const PlanningStatsPage());

      default:
        print('Route not found in CoachRoutes: ${settings.name}');
        return null; // Allow fallback in other routes
    }
  }
}
