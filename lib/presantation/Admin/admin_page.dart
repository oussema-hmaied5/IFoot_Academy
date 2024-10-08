// ignore_for_file: library_private_types_in_public_api, empty_catches, no_leading_underscores_for_local_identifiers

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ifoot_academy/presantation/Admin/Events/events_page.dart';
import 'package:ifoot_academy/presantation/Admin/Groupes/groupes_page.dart';
import 'package:ifoot_academy/presantation/Admin/Regulation/regulation_page.dart';
import 'package:ifoot_academy/presantation/Admin/Users/users_page.dart';
import 'package:ifoot_academy/presantation/Calender/training_page.dart';
import 'package:ifoot_academy/presantation/Drawer/Drawerback.dart';

import 'Menu/footer.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  _AdminMainPageState createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int pendingUserCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPendingUserCount();
  }

  Future<void> _fetchPendingUserCount() async {

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pending')
          .get();

      // Debugging statement to confirm the number of fetched users

      setState(() {
        pendingUserCount = snapshot.docs.length;
        // Confirm that the count has been updated in the state
      });

      setState(() {});  // Force a rebuild of the widget tree to reflect the changes in the UI
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Principale Admin'),
        actions: [
          _buildPendingUserIcon(),
        ],
      ),
      drawer: const DrawerBApp(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(_width * 0.05),
                child: Column(
                  children: [
                    _buildSectionTitle('Tous les Utilisateurs '),
                    _buildNavigationButton('Voir les Utilisateurs et Entraîneurs', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageUsersPage()));
                    }),
                    _buildSectionTitle('Gérer les Groupes'),
                    _buildNavigationButton('Aller aux Groupes', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageGroupsPage()));
                    }),
                    _buildSectionTitle('Gérer les Événements'),
                    _buildNavigationButton('Aller aux Événements', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageEventsPage()));
                    }),
                    _buildSectionTitle('Gérer les Régulations'),
                    _buildNavigationButton('Aller aux Régulations', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageRegulationsPage()));
                    }),
                    _buildSectionTitle('Gérer les Entraînements'),
                    _buildNavigationButton('Aller aux Entraînements', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TrainingCalendarPage()));
                    }),
                  ],
                ),
              ),
              // Add the footer at the end of the scrollable page
              Footer(), // Add the styled footer at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingUserIcon() {
    return badges.Badge(
      badgeContent: Text(
        pendingUserCount > 0 ? pendingUserCount.toString() : '',
        style: const TextStyle(color: Colors.white),
      ),
      showBadge: pendingUserCount > 0,
      child: IconButton(
        icon: Icon(
          Icons.notifications,
          color: pendingUserCount > 0 ? Colors.red : Colors.white,  // Change icon color if there are pending users
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ManageUsersPage(filterRole: 'pending')),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNavigationButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
