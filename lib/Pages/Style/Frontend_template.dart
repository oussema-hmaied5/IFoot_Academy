  // ignore: file_names
  // ignore_for_file: file_names, duplicate_ignore

  import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'drawer.dart'; // Your specific drawer class (DrawerApp)

  class FrontendTemplate extends StatelessWidget {
    final String title;
    final Widget body;
    final int footerIndex;
    final FloatingActionButton? floatingActionButton;

    const FrontendTemplate({
      Key? key,
      required this.title,
      required this.body,
      this.footerIndex = 0,
      this.floatingActionButton,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: const DrawerApp(),
        body: _buildBody(context),
        bottomNavigationBar: _buildBottomNavBar(context),
        floatingActionButton: floatingActionButton,
      );
    }

    PreferredSizeWidget _buildAppBar() {
      return AppBar(
        title: Text(title),
        backgroundColor: Colors.teal, // Teal color for a fresh, sporty look
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add notifications logic
            },
          ),
        ],
      );
    }

    Widget _buildBody(BuildContext context) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: body,
      );
    }

    Widget _buildBottomNavBar(BuildContext context) {
      return BottomNavigationBar(
        currentIndex: footerIndex,
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        selectedItemColor: Colors.teal, // Highlight selected item
        unselectedItemColor: Colors.grey, // Non-selected items color
        onTap: (index) {
          final user = FirebaseAuth.instance.currentUser; // Get the current user

          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not logged in')),
            );
            return;
          }

          // Handle navigation based on the selected index
          if (index == 0) {
            Navigator.of(context)
                .pushReplacementNamed('/main', arguments: user.uid);
          } else if (index == 1) {
            Navigator.of(context)
                .pushReplacementNamed('/myTeam', arguments: user.uid);
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/training');
          } else if (index == 3) {
            Navigator.of(context).pushReplacementNamed(
              '/UserGroupChat',
              arguments: {
                'groupId':
                    'admin_dynamic_id', // Fetch dynamically from your database or app state
                'groupName': 'Admin Chat Room', // Replace with dynamic group name
              },
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Acceuil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Mon groupe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Entrainement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Group Chat',
          ),
        ],
      );
    }
  }
