import 'package:flutter/material.dart';

class AppConstants {
  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String adminRoute = '/admin';
  static const String coachDashboardRoute = '/coachDashboard';

  // App-wide Strings
  static const String appTitle = 'iFoot Academy';
  static const String errorMessage = 'Something went wrong. Please try again.';
  static const String noDataMessage = 'No data available at the moment.';

  // Colors
  static const Color primaryColor = Color(0xFF176174); // Adjust as per your theme
  static const Color accentColor = Color(0xFF00A9CE);
  static const Color errorColor = Colors.red;

  // Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String coachesCollection = 'coaches';
  static const String groupsCollection = 'groups';
  static const String eventsCollection = 'events';
}
