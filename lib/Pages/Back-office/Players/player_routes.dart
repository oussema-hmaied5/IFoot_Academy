import 'package:flutter/material.dart';

import 'Calender_player/training_calender.dart';
import 'Events/events_page.dart';
import 'Groupes/add_groupe_page.dart';
import 'Groupes/all_groupes_page.dart';
import 'Users/all_users_page.dart';

class PlayerRoutes {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      // User Management
      case '/manageUsers':
        return MaterialPageRoute(builder: (_) => const ManageUsersPage());

      // Group Management
      case '/manageGroups':
        return MaterialPageRoute(builder: (_) => const ManageGroupsPage());
      case '/addGroup':
        return MaterialPageRoute(builder: (_) => const AddGroupPage());
      // My Team
      case '/manageTraining':
        return MaterialPageRoute(builder: (_) => const TrainingCalendarPage());

      // Events
      case '/manageEvents':
        return MaterialPageRoute(builder: (_) =>  const EventManager());

      default:
        return null;
    }
  }

}
