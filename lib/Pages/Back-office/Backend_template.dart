// ignore_for_file: file_names

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
  final bool isCoach;
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actions;

  const TemplatePageBack({
    Key? key,
    required this.title,
    required this.body,
    this.footerIndex = 0,
    this.isCoach = false,
    this.floatingActionButton,
    this.actions,
  }) : super(key: key);

  Future<String> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Utilisateur';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'Utilisateur';
      } else {
        return 'Utilisateur';
      }
    } catch (e) {
      return 'Utilisateur';
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
            actions: actions,
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
