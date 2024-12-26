import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Authentification/services/logout_handler.dart';
import '../Backend/Menu/footer.dart';
import 'Drawerback.dart';

class TemplatePageBack extends StatelessWidget {
  final String title;
  final Widget body;
  final int footerIndex;
  final FloatingActionButton? floatingActionButton;

  const TemplatePageBack({
    Key? key,
    required this.title,
    required this.body,
    this.footerIndex = 0,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Utilisateur';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo[900], // Common color for the app
      ),
      drawer: DrawerBApp(
        userName: userName, // Utilise le nom d'utilisateur depuis Firebase
        onSignOut: () async {
          await LogoutHandler.logout(context); // Gestion de la déconnexion
        },
      ), // Include your Drawer
      body: body, // The page's main content
      bottomNavigationBar:
          Footer(currentIndex: footerIndex), // Include your Footer
      floatingActionButton:
          floatingActionButton, // Add the floating action button here
    );
  }
}
