// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DrawerApp extends StatefulWidget {
  const DrawerApp({Key? key}) : super(key: key);

  @override
  _DrawerAppState createState() => _DrawerAppState();
}

class _DrawerAppState extends State<DrawerApp> {
  String userName = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
 
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data != null) {
          setState(() {
            userName = data['name'] ?? 'User';
          });
        }
      }
   
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/');
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff003542)),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'FontR',
          fontSize: 18,
          color: Colors.teal,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xff003542),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(Icons.person, 'Profile', () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Navigator.of(context).pushNamed(
                        '/profile',
                        arguments: user.uid,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                    }
                  }),
                  _buildMenuItem(Icons.group, 'Mon Équipe', () {
                    Navigator.of(context).pushNamed('/myTeam');
                  }),
                  _buildMenuItem(Icons.info, 'About Us', () {
                    Navigator.of(context).pushNamed('/aboutUs');
                  }),
                  _buildMenuItem(Icons.contact_phone, 'Contact Us', () {
                    Navigator.of(context).pushNamed('/contactUs');
                  }),
                  _buildMenuItem(Icons.feedback, 'Feedback', () {
                    Navigator.of(context).pushNamed('/feedback');
                  }),
                  const Divider(),
                  _buildMenuItem(Icons.notifications, 'Notifications', () {
                    Navigator.of(context).pushNamed('/notifications');
                  }),
                  _buildMenuItem(Icons.event, 'Événements', () {
                    Navigator.of(context).pushNamed('/events');
                  }),
                  _buildMenuItem(Icons.settings, 'Settings', () {
                    Navigator.of(context).pushNamed('/settings');
                  }),
                  _buildMenuItem(Icons.info, 'About Us', () {
                    Navigator.of(context).pushNamed('/aboutUs');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
