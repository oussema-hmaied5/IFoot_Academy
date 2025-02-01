import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Authentification/services/logout_handler.dart';
import 'Shared/widgets/Drawerback.dart';
import 'Shared/widgets/footer.dart';

class TemplatePageBack extends StatelessWidget {
  final String title;
  final Widget body;
  final int footerIndex;
  final bool isCoach; // Determines if in coach space or player space
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actions; // Added actions parameter to allow AppBar buttons

  const TemplatePageBack({
    Key? key,
    required this.title,
    required this.body,
    this.footerIndex = 0,
    this.isCoach = false, // Default is player space
    this.floatingActionButton,
    this.actions, // Allow optional actions
  }) : super(key: key);

  Future<String> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Utilisateur'; // Fallback if user is not logged in

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'Utilisateur'; // Use 'name' field
      } else {
        return 'Utilisateur';
      }
    } catch (e) {
      return 'Utilisateur'; // Fallback in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchUserName(),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Utilisateur';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: const Color.fromARGB(255, 23, 97, 116),
            actions: actions, // Use the actions parameter
          ),
          drawer: DrawerBApp(
            userName: userName,
            onSignOut: () async {
              await LogoutHandler.logout(context);
            },
          ),
          body: body,
          bottomNavigationBar: Footer(
            currentIndex: footerIndex,
            isCoach: isCoach,
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
